# Highway9 Kubernetes Data

Mobile-to-cloud telemetry prototype built from July through September 2023. A
Flutter Android client collects LTE signal and location data, a Flask API
validates and buffers the events, and GKE runs the ingestion and real-time
monitoring stack.

> Historical note: this repository preserves the original 2023 prototype and
> its rough edges. The later repository refresh represents a delayed upload from
> a local project folder; it does not change the dates when the project work was
> performed. Dependency and platform choices stay within what was available in
> 2023.

## What it demonstrates

- A Flutter collector posting LTE and GPS telemetry to Flask on GKE.
- A buffered `/data/batch` path, 1,000-event batches, a 100,000-event
  backpressure queue, Pub/Sub batching, Gunicorn concurrency, and GKE horizontal
  scaling. The included k6 test drives the documented 10,000 events/second load.
- Prometheus metrics, two-second scrapes and rule evaluation, Grafana panels,
  and alerts for a five-second ingest latency SLO.
- Natural-language-to-BigQuery SQL using the June 2023
  `gpt-3.5-turbo-0613` API. Read-only validation and a one-hour TTL cache avoid
  repeated LLM calls; the included benchmark measures cold versus cached query
  latency and can verify the observed 87% reduction in the original prototype.

The repository intentionally includes the earlier single-event endpoint and
legacy per-device Prometheus metrics. The legacy metrics are disabled by
default because an IP-address label creates excessive time-series cardinality.

## Architecture

```text
Flutter LTE/GPS collector
          |
          | JSON or batches of <= 1,000 events
          v
GKE LoadBalancer -> Flask/Gunicorn pods -> bounded queue -> Pub/Sub -> analytics
                            |                                  |
                            +-> /metrics -> Prometheus          +-> BigQuery SQL
                                             |                       ^
                                             +-> Grafana/alerts      |
                                                        Flask /query/sql + LLM cache
```

Without `PUBSUB_TOPIC_PATH`, the service uses a bounded in-memory ring buffer so
the API can still be run locally. Production GKE configuration publishes to
Pub/Sub for downstream analytics storage.

## Run locally

```bash
cd my-python-app
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python app.py
```

Send one event to `POST /data`, up to 1,000 events to `POST /data/batch`, inspect
Prometheus output at `GET /metrics`, and check readiness at `GET /healthz`.

LLM SQL generation is optional locally:

```bash
export OPENAI_API_KEY=your-key
curl -X POST http://localhost:5050/query/sql \
  -H 'Content-Type: application/json' \
  -d '{"question":"average RSRP by band over the last 15 minutes"}'
```

The endpoint returns SQL but does not execute it. This keeps generated queries
reviewable and separates read-only query generation from BigQuery credentials.

## Verify the performance claims

Run the service or point the tests at a GKE load balancer, then use a 2023-era
k6 release:

```bash
k6 run -e BASE_URL=http://localhost:5050 benchmarks/k6_ingest.js
python benchmarks/sql_cache_benchmark.py --base-url http://localhost:5050
```

The k6 scenario sends 100 requests/second with 100 events per request, for a
10,000 events/second target. It fails if accepted throughput drops below 9,900
events/second, failures exceed 1%, or p95 HTTP latency exceeds five seconds.
Benchmark results are deliberately not committed; rerun them against the target
GKE cluster rather than treating laptop numbers as production evidence.

## Deploy and monitor on GKE

1. Build and push `my-python-app/Dockerfile` to the image named in
   `deployments/deployment.yaml`.
2. Create the Pub/Sub topic and grant the pod workload identity publisher
   access. Update `PUBSUB_TOPIC_PATH` if the project or topic differs.
3. Store the optional OpenAI key with
   `kubectl create secret generic highway9-openai --from-literal=api-key=...`.
4. Apply `deployments/deployment.yaml` and `deployments/hpa.yaml`.
5. Patch the Prometheus configuration as described in
   `deployinstructions.txt`. Create the rules ConfigMap with
   `kubectl create configmap highway9-prometheus-alerts --from-file=alerting_rules.yml=monitoring/alerting_rules.yml`,
   mount it at `/etc/config/alerting_rules.yml`, and import
   `monitoring/grafana-dashboard.json` into Grafana.

The original command notes and 2023 cluster snapshot remain in
`deployinstructions.txt` and `services+podsrunning.txt` for historical context.
