from flask import Flask
from prometheus_client import CollectorRegistry, Gauge, push_to_gateway

app = Flask(__name__)

# Create Prometheus registry
registry = CollectorRegistry()
# Create the gauge metric for the data table
gauge_metric = Gauge('my_data_table_metric', 'My data table metric', ['name'],
                     registry=registry)

@app.route('/')
def hello():
    data_table = [
        {'id': 1, 'name': 'Entry 1'},
        {'id': 2, 'name': 'Entry 2'},
        {'id': 3, 'name': 'Entry 3'},
    ]

    # Transform data table to Prometheus metrics
    for entry in data_table:
        gauge_metric.labels(entry['name']).set(entry['id'])

    # Push all metrics to the Pushgateway
    #Job name is used to distinguish between different deployments
    #or if you want to filter metrics for this job name
    push_to_gateway('10.116.11.204:9091', job='my-flask-app', registry=registry)

    return 'Hello, World!'

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5050)
