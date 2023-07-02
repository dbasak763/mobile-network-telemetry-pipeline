# Highway9KubernetesData
# i created a folder called my-python-app that contains (app.py, Dockerfile, requirements.txt), and prometheus.yml
# To build DockerImage from Dockerfile that runs app.py with dependencies from requirements.txt, run docker build, docker push
# i created a folder for deploymentfiles in which i created deployment.yaml 
# after pushing docker image to container, run kubectl apply -f deployment.yaml from folder
# should apply changes
# i used helm to get latest versions of prometheus and grafana running
# Couldn't edit the prometheus.yml(read-only) file within Prometheus repo used inside deployment, responsible for adding targets and scrape configs, so had to create own version of prometheus.yml, make modifications, and patch that to the deployment of prometheus
# Updated main.dart in h9_test to send POST request with JSON payload data to flask app server which will be pushed to prometheus for scraping, scraping happens every 1 min
# Could use Postman to test this
