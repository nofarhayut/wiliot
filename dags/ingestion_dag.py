"""
Orders ingestion pipeline (Wiliot demo).

    extract   -> GET the Microcks mock (dynamic dummy orders)
    transform -> plain-Python cleanup/reshape (cast types, drop bad rows)
    load      -> upsert into RDS Postgres via Airflow connection `rds_postgres`

Idempotent by design: CREATE TABLE IF NOT EXISTS + INSERT ... ON CONFLICT DO
NOTHING, so re-running never duplicates rows. Uses only packages already in the
Airflow image (requests + the standard & postgres providers) — no custom image.
"""
from __future__ import annotations

import datetime as dt

import requests
from airflow import DAG
from airflow.providers.postgres.hooks.postgres import PostgresHook
from airflow.providers.standard.operators.python import PythonOperator

# In-cluster Microcks mock endpoint: <service>.<namespace>.svc.cluster.local
MOCK_URL = "http://microcks.microcks.svc.cluster.local:8080/rest/Orders/1.0.0/orders"
RDS_CONN_ID = "rds_postgres"  # injected into pods via the rds-connection secret
TABLE = "orders"

CREATE_TABLE_SQL = f"""
CREATE TABLE IF NOT EXISTS {TABLE} (
    order_id    TEXT PRIMARY KEY,
    customer    TEXT,
    email       TEXT,
    amount      INTEGER,
    created_at  TIMESTAMPTZ,
    ingested_at TIMESTAMPTZ DEFAULT now()
);
"""

INSERT_SQL = f"""
INSERT INTO {TABLE} (order_id, customer, email, amount, created_at)
VALUES (%(order_id)s, %(customer)s, %(email)s, %(amount)s, %(created_at)s)
ON CONFLICT (order_id) DO NOTHING;
"""


def extract(**context):
    """Pull a fresh batch of dummy orders from the Microcks mock."""
    resp = requests.get(MOCK_URL, timeout=30)
    resp.raise_for_status()
    orders = resp.json()
    print(f"extracted {len(orders)} orders from {MOCK_URL}")
    context["ti"].xcom_push(key="raw_orders", value=orders)


def transform(**context):
    """Cast/clean the raw records; drop anything without an id or valid amount."""
    raw = context["ti"].xcom_pull(key="raw_orders", task_ids="extract") or []
    cleaned = []
    for o in raw:
        if not o.get("order_id"):
            continue
        try:
            amount = int(o["amount"])  # mock returns amount as a string
        except (KeyError, TypeError, ValueError):
            continue
        cleaned.append(
            {
                "order_id": o["order_id"],
                "customer": (o.get("customer") or "").strip(),
                "email": (o.get("email") or "").strip().lower(),
                "amount": amount,
                "created_at": o.get("created_at"),
            }
        )
    print(f"transformed {len(cleaned)}/{len(raw)} orders")
    context["ti"].xcom_push(key="clean_orders", value=cleaned)


def load(**context):
    """Upsert into RDS. Idempotent: existing order_ids are skipped."""
    rows = context["ti"].xcom_pull(key="clean_orders", task_ids="transform") or []
    hook = PostgresHook(postgres_conn_id=RDS_CONN_ID)
    conn = hook.get_conn()
    with conn.cursor() as cur:
        cur.execute(CREATE_TABLE_SQL)
        if rows:
            cur.executemany(INSERT_SQL, rows)
    conn.commit()
    print(f"loaded {len(rows)} orders into RDS table '{TABLE}' (duplicates skipped)")


with DAG(
    dag_id="orders_ingestion",
    description="Microcks -> transform -> RDS Postgres (Wiliot demo)",
    schedule="*/15 * * * *",  # every 15 minutes
    start_date=dt.datetime(2026, 1, 1),
    catchup=False,
    tags=["wiliot", "demo", "etl"],
) as dag:
    t_extract = PythonOperator(task_id="extract", python_callable=extract)
    t_transform = PythonOperator(task_id="transform", python_callable=transform)
    t_load = PythonOperator(task_id="load", python_callable=load)

    t_extract >> t_transform >> t_load
