import os
import time

from flask import Flask, Response, jsonify, request
from jsonschema import Draft7Validator, FormatChecker
from prometheus_client import (
    CollectorRegistry,
    Counter,
    Gauge,
    Histogram,
    Info,
    generate_latest,
)

from schema import schema
from sql_generator import SQLGenerator, SQLGeneratorError
from telemetry_pipeline import TelemetryPipeline


app = Flask(__name__)
registry = CollectorRegistry()
validator = Draft7Validator(schema, format_checker=FormatChecker())

events_received = Counter(
    'telemetry_events_received_total',
    'Validated telemetry events accepted by the API',
    registry=registry,
)
events_rejected = Counter(
    'telemetry_events_rejected_total',
    'Telemetry events rejected by validation or backpressure',
    ['reason'],
    registry=registry,
)
request_latency = Histogram(
    'telemetry_ingest_request_seconds',
    'Time spent validating and queueing telemetry requests',
    buckets=(.005, .01, .025, .05, .1, .25, .5, 1, 2, 5),
    registry=registry,
)
batch_size = Histogram(
    'telemetry_ingest_batch_size',
    'Number of events supplied in each request',
    buckets=(1, 10, 25, 50, 100, 250, 500, 1000),
    registry=registry,
)
queue_depth = Gauge(
    'telemetry_pipeline_queue_depth',
    'Events waiting to be published to the analytics backend',
    registry=registry,
)
publish_latency = Histogram(
    'telemetry_publish_seconds',
    'Time to hand a telemetry batch to the analytics backend',
    buckets=(.005, .01, .025, .05, .1, .25, .5, 1, 2, 5),
    registry=registry,
)
published_events = Counter(
    'telemetry_events_published_total',
    'Events handed to the analytics backend',
    ['backend'],
    registry=registry,
)
publish_errors = Counter(
    'telemetry_publish_errors_total',
    'Telemetry batches that could not be handed to the analytics backend',
    ['backend'],
    registry=registry,
)
sql_generation_latency = Histogram(
    'telemetry_sql_generation_seconds',
    'Time spent generating or retrieving SQL',
    ['cache'],
    buckets=(.001, .005, .01, .05, .1, .25, .5, 1, 2, 5),
    registry=registry,
)

# Kept for compatibility with the original 2023 Grafana panels. These metrics
# are opt-in because an IP label creates too many Prometheus time series at scale.
gauge_metric = Gauge(
    'my_data_table_metric',
    'Legacy numeric device metric',
    ['ipaddress', 'param'],
    registry=registry,
)
info_metric = Info(
    'my_data_table_string_metric',
    'Legacy string device metric',
    ['ipaddress', 'param'],
    registry=registry,
)


def update_legacy_metrics(data):
    if os.getenv('ENABLE_LEGACY_DEVICE_METRICS', 'false').lower() != 'true':
        return

    device_info = data['device_information']['device_info']
    location = data['device_information']['location']
    lte_params = data['lte_params']
    ip_address = data['ip-address']

    numeric_values = {
        'latitude': location['latitude'],
        'longitude': location['longitude'],
        'altitude': location['altitude'],
        'accuracy': location['accuracy'],
        'Fc': lte_params['Fc'],
        'EarFcn': lte_params['EarFcn'],
        'TimeAdv': lte_params['TimeAdv'],
        'pci': lte_params['pci'],
        'rsrp': lte_params['rsrp'],
        'rsrq': lte_params['rsrq'],
        'rssi': lte_params['rssi'],
        'snr': lte_params['snr'],
        'cqi': lte_params['cqi'],
    }
    for name, value in numeric_values.items():
        gauge_metric.labels(ipaddress=ip_address, param=name).set(float(value))

    string_values = {
        'model': device_info['model'],
        'android': device_info['android'],
        'hardware': device_info['hardware'],
        'timestamp': data['device_information']['timestamp'],
        'mcc': lte_params['mcc'],
        'mnc': lte_params['mnc'],
        'band': lte_params['band'],
        'tac': lte_params['tac'],
        'eci': lte_params['eci'],
    }
    for name, value in string_values.items():
        info_metric.labels(ipaddress=ip_address, param=name).info({'value': value})


pipeline = TelemetryPipeline(
    queue_depth_metric=queue_depth,
    publish_latency_metric=publish_latency,
    published_events_metric=published_events,
    publish_errors_metric=publish_errors,
    on_event=update_legacy_metrics,
)
sql_generator = SQLGenerator()


@app.route('/')
def hello():
    return jsonify({
        'service': 'highway9-telemetry',
        'status': 'ready',
        'pipeline_backend': pipeline.backend_name,
    })


@app.route('/healthz')
def health():
    return jsonify({'status': 'ok', 'queue_depth': pipeline.queue_depth})


@app.route('/metrics')
def metrics():
    return Response(generate_latest(registry), mimetype='text/plain; version=0.0.4')


def _validation_error(event):
    error = next(validator.iter_errors(event), None)
    if error is None:
        return None
    path = '.'.join(str(part) for part in error.absolute_path)
    return '{}: {}'.format(path or 'payload', error.message)


def _receive_events(payload):
    events = payload if isinstance(payload, list) else [payload]
    if not events or len(events) > 1000:
        events_rejected.labels(reason='batch_size').inc(len(events) or 1)
        return jsonify({'message': 'Batch must contain between 1 and 1000 events'}), 400

    for index, event in enumerate(events):
        error = _validation_error(event)
        if error:
            events_rejected.labels(reason='validation').inc()
            return jsonify({'message': 'Data validation failed', 'index': index, 'error': error}), 400

    if not pipeline.enqueue_many(events):
        events_rejected.labels(reason='queue_full').inc(len(events))
        return jsonify({'message': 'Telemetry queue is full; retry later'}), 503

    events_received.inc(len(events))
    batch_size.observe(len(events))
    return jsonify({'message': 'Data accepted', 'accepted': len(events)}), 202


@app.route('/data', methods=['POST'])
@app.route('/data/batch', methods=['POST'])
def receive_data():
    started = time.time()
    try:
        payload = request.get_json(silent=True)
        if payload is None:
            events_rejected.labels(reason='invalid_json').inc()
            return jsonify({'message': 'A JSON request body is required'}), 400
        return _receive_events(payload)
    finally:
        request_latency.observe(time.time() - started)


@app.route('/query/sql', methods=['POST'])
def generate_sql():
    payload = request.get_json(silent=True) or {}
    question = str(payload.get('question', '')).strip()
    if not question:
        return jsonify({'message': 'question is required'}), 400

    started = time.time()
    try:
        sql, cache_hit = sql_generator.generate(question)
    except SQLGeneratorError as error:
        return jsonify({'message': str(error)}), 503
    finally:
        elapsed = time.time() - started

    sql_generation_latency.labels(cache='hit' if cache_hit else 'miss').observe(elapsed)
    return jsonify({'question': question, 'sql': sql, 'cache_hit': cache_hit})


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5050, threaded=True)
