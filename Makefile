# Wiliot demo — Microcks dummy-data API + Airflow ingestion DAG.
# Prereqs: kubectl + helm installed, kubeconfig pointed at the wiliot-dev cluster:
#   AWS_PROFILE=nofar-yaba aws eks update-kubeconfig --name wiliot-dev --region us-east-1

AWS_PROFILE ?= nofar-yaba
AWS_REGION  ?= us-east-1
export AWS_PROFILE
export AWS_REGION

MICROCKS_NS            ?= microcks
AIRFLOW_NS             ?= airflow
MICROCKS_CHART_VERSION ?= 1.14.0
AIRFLOW_CHART_VERSION  ?= 1.22.0

.PHONY: deploy microcks mock dags airflow-upgrade verify clean

## deploy: full pipeline — Microcks + mock + DAG ConfigMap + Airflow mount
deploy: microcks mock dags airflow-upgrade
	@echo ">> Pipeline deployed. See README 'Demo script' to run it."

## microcks: install Microcks (auth off, ephemeral Mongo, ClusterIP)
microcks:
	helm repo add microcks https://microcks.io/helm
	helm repo update
	helm upgrade --install microcks microcks/microcks \
	  --namespace $(MICROCKS_NS) --create-namespace \
	  --version $(MICROCKS_CHART_VERSION) \
	  -f helm/microcks/values.yaml --timeout 10m

## mock: import the Orders OpenAPI mock into Microcks
mock:
	./scripts/load-mock.sh

## dags: (re)build the DAG ConfigMap from ./dags (run after editing a DAG)
dags:
	kubectl -n $(AIRFLOW_NS) create configmap airflow-dags \
	  --from-file=dags/ --dry-run=client -o yaml | kubectl apply -f -

## airflow-upgrade: re-apply Airflow so it mounts the DAG ConfigMap
airflow-upgrade:
	helm upgrade airflow apache-airflow/airflow \
	  --namespace $(AIRFLOW_NS) --version $(AIRFLOW_CHART_VERSION) \
	  -f helm/airflow/values.yaml --timeout 10m

## verify: show Microcks + Airflow pods
verify:
	kubectl -n $(MICROCKS_NS) get pods
	kubectl -n $(AIRFLOW_NS) get pods

## clean: remove ONLY Microcks + the DAG ConfigMap (leaves Terraform/EKS/RDS/Airflow)
clean:
	-helm uninstall microcks -n $(MICROCKS_NS)
	-kubectl delete namespace $(MICROCKS_NS)
	-kubectl -n $(AIRFLOW_NS) delete configmap airflow-dags
	@echo ">> Removed Microcks and the DAG ConfigMap. Infra + Airflow untouched."
