#!/usr/bin/env bash
set -euo pipefail

TENANT=${1:-tenant-x}
NAMESPACE=${TENANT}
BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "Provisioning tenant: $TENANT in namespace $NAMESPACE"

kubectl create ns "$NAMESPACE" || true

# Apply ResourceQuota template (you can edit path)
kubectl apply -n "$NAMESPACE" -f "$BASE_DIR/k8s/tenant/resourcequota.yaml"

# Deploy fake-gpu (use the yaml but replace namespace)
kubectl apply -n "$NAMESPACE" -f "$BASE_DIR/k8s/dcgm/fake-gpu.yaml"
kubectl apply -n "$NAMESPACE" -f "$BASE_DIR/k8s/dcgm/fake-gpu-service.yaml"

# Apply ServiceMonitor (assumes prometheus-operator present)
kubectl apply -n "$NAMESPACE" -f "$BASE_DIR/k8s/monitoring/servicemonitor.yaml"

echo "Waiting for fake-gpu pod to be ready..."
kubectl wait --for=condition=ready pod -l app=fake-gpu -n "$NAMESPACE" --timeout=120s || {
  echo "Pod not ready yet. Check 'kubectl get pods -n $NAMESPACE' and logs."
}

echo "Tenant $TENANT provisioned."

# Optional: push Grafana dashboard via API
if [[ -n "${GRAFANA_URL:-}" && -n "${GRAFANA_API_KEY:-}" ]]; then
  echo "Pushing Grafana dashboard..."
  DASH_JSON_PATH="$BASE_DIR/k8s/monitoring/grafana-dashboard.json"
  curl -s -X POST "${GRAFANA_URL}/api/dashboards/db" \
    -H "Authorization: Bearer ${GRAFANA_API_KEY}" \
    -H "Content-Type: application/json" \
    -d @"${DASH_JSON_PATH}" | jq .
fi

echo "Done."
