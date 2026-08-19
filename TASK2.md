# Task 2 — Data pipeline (Microcks + Airflow)

> 📊 **[View the visual overview →](https://claude.ai/code/artifact/29d1c357-e968-43d0-9e68-298841ba8b43)** — a one-page presentation of the whole assignment.

An Airflow job pulls dummy data from a Microcks mock API every 15 minutes, cleans it in
plain Python, and loads it into the managed RDS PostgreSQL — a small **ETL pipeline**
(extract → transform → load) running on the Task 1 infrastructure.

## The data flow

```
   AIRFLOW                      MICROCKS                     RDS POSTGRES
  (orchestrator)   ───▶      (mock data source)   ───▶      (managed datastore)
 schedules and runs         exposes an API that          persists the transformed
 the ETL pipeline           returns dummy order          records as the pipeline's
 every 15 minutes           data on request              system of record
```

The DAG itself does the ETL: **extract** (call the mock) → **transform** (clean the data)
→ **load** (write to RDS).

## What each part does

| Part | Code | What it does |
|---|---|---|
| **Microcks** | [`helm/microcks`](helm/microcks) | A mock API, installed from its official Helm chart. Serves `GET /orders` and returns ~20 random orders per call ([`mocks/orders-openapi.yaml`](mocks/orders-openapi.yaml)). Auth off, throwaway DB — demo settings. |
| **Airflow** | [`helm/airflow`](helm/airflow) | The orchestrator. Its scheduler runs the job on a timer, the dag-processor reads the DAG file, and the web UI is exposed to the internet through a load balancer. |
| **The DAG** | [`dags/ingestion_dag.py`](dags/ingestion_dag.py) | Three steps — `extract`, `transform`, `load`. Idempotent (`CREATE TABLE IF NOT EXISTS` + `ON CONFLICT DO NOTHING`), so it's safe to re-run. Uses only packages already in the Airflow image. |
| **DAG delivery** | ConfigMap | The DAG file is packed into a ConfigMap and mounted into Airflow (no git-sync, no PVC, no custom image). |
| **RDS connection** | [`modules/rds`](modules/rds) | The DB connection string is injected into Airflow as a Kubernetes secret, so the DAG uses it by name (`rds_postgres`) and no password sits in the code. |

## Deploy

```bash
export AWS_PROFILE=nofar-yaba AWS_REGION=us-east-1
aws eks update-kubeconfig --name wiliot-dev --region us-east-1
make deploy    # install Microcks -> load the mock -> pack the DAG -> mount into Airflow
```

## How to look at things

Standard `kubectl`, runnable from any machine with access to the cluster.

```bash
# what's running
kubectl -n airflow  get pods        # api-server, scheduler, dag-processor, db
kubectl -n microcks get pods        # microcks, mongodb

# the DAG: is it registered? any parse errors?
kubectl -n airflow exec deploy/airflow-scheduler -c scheduler -- airflow dags list
kubectl -n airflow exec deploy/airflow-scheduler -c scheduler -- airflow dags list-import-errors

# tail a component's logs
kubectl -n airflow logs deploy/airflow-dag-processor -c dag-processor

# open the Airflow UI  ->  http://localhost:8080 (admin / admin)
kubectl -n airflow port-forward svc/airflow-api-server 8080:8080

# open Microcks and pull a batch of dummy orders
kubectl -n microcks port-forward svc/microcks 8585:8080
curl -s http://localhost:8585/rest/Orders/1.0.0/orders | jq '.[0]'

# the payoff: rows that landed in RDS
kubectl -n airflow exec deploy/airflow-scheduler -c scheduler -- python -c \
"from airflow.providers.postgres.hooks.postgres import PostgresHook; \
print(PostgresHook('rds_postgres').get_first('SELECT count(*) FROM orders'))"
```

## Clean up

```bash
make clean    # removes ONLY Microcks + the DAG ConfigMap (leaves infra/EKS/RDS/Airflow)
```
