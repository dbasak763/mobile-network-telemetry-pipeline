from flask import Flask, request, jsonify
from prometheus_client import CollectorRegistry, Gauge, push_to_gateway
from jsonschema import validate, ValidationError
from schema import schema

app = Flask(__name__)

# Create Prometheus registry
registry = CollectorRegistry()

# Create the gauge metric for the data table
gauge_metric = Gauge('my_data_table_metric', 'My data table metric',
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

    #debug statement
    #return jsonify({'message': 'Reached this point'})
    #Error happening when setting gauge metric values with labels
    # Set the gauge metric values with labels

    #gauge_metric.labels(ipaddress=ip_address, param='model').set(device_info['model'])
    
    #gauge_metric.labels(ipaddress=ip_address, param='android').set(device_info['android'])
    #gauge_metric.labels(ipaddress=ip_address, param='hardware').set(device_info['hardware'])
    #gauge_metric.labels(ipaddress=ip_address, param='latitude').set(location['latitude'])
    #gauge_metric.labels(ipaddress=ip_address, param='longitude').set(location['longitude'])
    #gauge_metric.labels(ipaddress=ip_address, param='altitude').set(location['altitude'])
    #gauge_metric.labels(ipaddress=ip_address, param='accuracy').set(location['accuracy'])
    #gauge_metric.labels(ipaddress=ip_address, param='timestamp').set(data['device_information']['timestamp'])
    #gauge_metric.labels(ipaddress=ip_address, param='mcc').set(lte_params['mcc'])
    #gauge_metric.labels(ipaddress=ip_address, param='mnc').set(lte_params['mnc']) 
    #gauge_metric.labels(ipaddress=ip_address, param='band').set(lte_params['band'])
    #gauge_metric.labels(ipaddress=ip_address, param='Fc').set(lte_params['Fc'])
    #gauge_metric.labels(ipaddress=ip_address, param='EarFcn').set(lte_params['EarFcn'])
    #gauge_metric.labels(ipaddress=ip_address, param='TimeAdv').set(lte_params['TimeAdv'])
    #gauge_metric.labels(ipaddress=ip_address, param='tac').set(lte_params['tac'])
    #gauge_metric.labels(ipaddress=ip_address, param='pci').set(lte_params['pci'])
    #gauge_metric.labels(ipaddress=ip_address, param='rsrp').set(lte_params['rsrp'])
    #gauge_metric.labels(ipaddress=ip_address, param='rsrq').set(lte_params['rsrq'])
    #gauge_metric.labels(ipaddress=ip_address, param='rssi').set(lte_params['rssi'])
    #gauge_metric.labels(ipaddress=ip_address, param='snr').set(lte_params['snr'])
    #gauge_metric.labels(ipaddress=ip_address, param='cqi').set(lte_params['cqi'])

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
