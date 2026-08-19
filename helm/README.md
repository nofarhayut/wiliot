# Airflow on EKS — Helm (manual install)

Airflow is deployed with the **Helm CLI** (not Terraform), per the assignment
("Deploy Airflow on EKS using Helm"). Terraform provisions the infrastructure;
Helm deploys the application on top of it.

## Prerequisites

- `kubectl` and `helm` installed
- The base infra applied (`environments/dev`) — cluster `wiliot-dev` is running
- AWS creds for the account (`AWS_PROFILE=nofar-yaba`)

## 1. Point kubectl at the cluster

```bash
AWS_PROFILE=nofar-yaba aws eks update-kubeconfig --name wiliot-dev --region us-east-1
kubectl get nodes            # expect 2 Ready nodes
```

## 2. Create the namespace

```bash
kubectl create namespace airflow
```

## 3. Create the RDS connection secret

DAGs read the RDS data store via conn_id `rds_postgres`. Build the URI from the
Terraform outputs (this avoids printing the password anywhere):

```bash
cd environments/dev
RDS_ENDPOINT=$(AWS_PROFILE=nofar-yaba terraform output -raw rds_endpoint)   # host:5432
RDS_HOST=${RDS_ENDPOINT%:*}
RDS_PASS=$(AWS_PROFILE=nofar-yaba terraform output -raw rds_password)
cd ../..

kubectl -n airflow create secret generic rds-connection \
  --from-literal=AIRFLOW_CONN_RDS_POSTGRES="postgresql://wiliot_admin:${RDS_PASS}@${RDS_HOST}:5432/wiliot"
```

## 4. Install Airflow

```bash
helm repo add apache-airflow https://airflow.apache.org
helm repo update

helm install airflow apache-airflow/airflow \
  --namespace airflow \
  --version 1.22.0 \
  -f helm/airflow/values.yaml \
  --timeout 20m
```

## 5. Get the external URL

The NLB takes ~2 minutes to get a DNS name.

```bash
kubectl -n airflow get svc airflow-webserver \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

Open `http://<that-hostname>:8080`. Default login is `admin` / `admin`
(change it for anything beyond a demo).

## Uninstall

```bash
helm uninstall airflow -n airflow
kubectl delete namespace airflow
```
