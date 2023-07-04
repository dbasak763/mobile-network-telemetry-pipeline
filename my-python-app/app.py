from flask import Flask, request, jsonify
from prometheus_client import CollectorRegistry, Gauge, Info, push_to_gateway
from jsonschema import validate, ValidationError
from schema import schema

app = Flask(__name__)

# Create Prometheus registry
registry = CollectorRegistry()

# Create the gauge metric for numerical values
gauge_metric = Gauge('my_data_table_metric', 'My data table metric',
                     ['ipaddress', 'param'], registry=registry)

# Create the info metric for string values
info_metric = Info('my_data_table_string_metric', 'My data table string metric',
                   ['ipaddress', 'param'], registry=registry)

@app.route('/')
def hello():
    return 'Hello, World!'

@app.route('/data', methods=['POST'])
def receive_data():
    # Allows access to JSON payload sent in the request
    data = request.json
    try:
        # Validate the received data against the schema
        validate(data, schema)
    except ValidationError as e:
        return jsonify({'message': 'Data validation failed', 'error': str(e)}), 400

    # Process the received data
    device_info = data['device_information']['device_info']
    location = data['device_information']['location']
    lte_params = data['lte_params']
    ip_address = data['ip-address']

    # Set the gauge metric values with labels
    gauge_metric.labels(ipaddress=ip_address, param='latitude').set(float(location['latitude']))
    gauge_metric.labels(ipaddress=ip_address, param='longitude').set(float(location['longitude']))
    gauge_metric.labels(ipaddress=ip_address, param='altitude').set(float(location['altitude']))
    gauge_metric.labels(ipaddress=ip_address, param='accuracy').set(float(location['accuracy']))
    gauge_metric.labels(ipaddress=ip_address, param='Fc').set(float(lte_params['Fc']))
    gauge_metric.labels(ipaddress=ip_address, param='EarFcn').set(float(lte_params['EarFcn']))
    gauge_metric.labels(ipaddress=ip_address, param='TimeAdv').set(float(lte_params['TimeAdv']))
    gauge_metric.labels(ipaddress=ip_address, param='pci').set(float(lte_params['pci']))
    gauge_metric.labels(ipaddress=ip_address, param='rsrp').set(float(lte_params['rsrp']))
    gauge_metric.labels(ipaddress=ip_address, param='rsrq').set(float(lte_params['rsrq']))
    gauge_metric.labels(ipaddress=ip_address, param='rssi').set(float(lte_params['rssi']))
    gauge_metric.labels(ipaddress=ip_address, param='snr').set(float(lte_params['snr']))
    gauge_metric.labels(ipaddress=ip_address, param='cqi').set(float(lte_params['cqi']))

    # Set the info metric values with labels
    info_metric.labels(ipaddress=ip_address, param='model').info({'value': device_info['model']})
    info_metric.labels(ipaddress=ip_address, param='android').info({'value': device_info['android']})
    info_metric.labels(ipaddress=ip_address, param='hardware').info({'value': device_info['hardware']})
    info_metric.labels(ipaddress=ip_address, param='timestamp').info({'value': data['device_information']['timestamp']})
    info_metric.labels(ipaddress=ip_address, param='mcc').info({'value': lte_params['mcc']})
    info_metric.labels(ipaddress=ip_address, param='mnc').info({'value': lte_params['mnc']})
    info_metric.labels(ipaddress=ip_address, param='band').info({'value': lte_params['band']})
    info_metric.labels(ipaddress=ip_address, param='band').info({'value': lte_params['band']})
    info_metric.labels(ipaddress=ip_address, param='tac').info({'value': lte_params['tac']})
    info_metric.labels(ipaddress=ip_address, param='eci').info({'value': lte_params['eci']})

    # Push all metrics to the Pushgateway
    push_to_gateway('10.116.11.204:9091', job='my-flask-app', registry=registry)

    # Construct the response JSON including received data
    response = {
        'data': data,
        'message': 'Data received successfully'
    }
    return jsonify(response)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5050)
