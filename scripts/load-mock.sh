#!/usr/bin/env bash
# Import the Orders OpenAPI mock into Microcks via its REST API.
# Auth is disabled (keycloak.enabled=false), so no bearer token is needed.
# We reach the ClusterIP service through a short-lived port-forward.
set -euo pipefail

NS="${MICROCKS_NS:-microcks}"
ARTIFACT="${ARTIFACT:-mocks/orders-openapi.yaml}"
LOCAL_PORT="${LOCAL_PORT:-8585}"

echo "Port-forwarding svc/microcks ${LOCAL_PORT} -> 8080 (ns=${NS}) ..."
kubectl -n "$NS" port-forward svc/microcks "${LOCAL_PORT}:8080" >/dev/null 2>&1 &
PF_PID=$!
trap 'kill "$PF_PID" 2>/dev/null || true' EXIT
sleep 5

echo "Uploading ${ARTIFACT} ..."
curl -sf -F "file=@${ARTIFACT}" \
  "http://localhost:${LOCAL_PORT}/api/artifact/upload?mainArtifact=true"
echo

echo "Imported. In-cluster mock URL:"
echo "  http://microcks.${NS}.svc.cluster.local:8080/rest/Orders/1.0.0/orders"
