#!/usr/bin/env bash
set -euo pipefail

STUDENT_ID="102783255"
CLUSTER_NAME="${STUDENT_ID}-hpa"
NAMESPACE="${STUDENT_ID}-hpa"

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "ERROR: required command not found: $1" >&2
    exit 1
  fi
}

require_command docker
require_command kind
require_command kubectl

echo "Checking Docker..."
docker info >/dev/null

echo "Creating kind cluster if needed..."
if ! kind get clusters | grep -Fxq "$CLUSTER_NAME"; then
  kind create cluster \
    --name "$CLUSTER_NAME" \
    --config kind-config.yaml
fi

kubectl config use-context "kind-${CLUSTER_NAME}"

echo "Installing metrics-server..."
kubectl apply -f manifests/metrics-server.yaml

echo "Creating namespace..."
kubectl apply -f manifests/00-namespace.yaml

echo "Creating Secret..."
kubectl apply -f manifests/01-secret.yaml

echo "Deploying application..."
kubectl apply -f manifests/02-app.yaml

echo "Creating Service..."
kubectl apply -f manifests/03-service.yaml

echo "Creating HPA..."
kubectl apply -f manifests/04-hpa.yaml

echo "Applying default ResourceQuota..."
./apply-quota.sh 6 1000m

echo "Waiting for metrics-server Deployment..."
kubectl rollout status \
  deployment/metrics-server \
  --namespace kube-system \
  --timeout=180s

echo "Waiting for metrics APIService..."
for attempt in $(seq 1 60); do
  if kubectl get --raw "/apis/metrics.k8s.io/v1beta1/nodes" >/dev/null 2>&1; then
    break
  fi

  if [ "$attempt" -eq 60 ]; then
    echo "ERROR: metrics API did not become available" >&2
    kubectl describe deployment metrics-server -n kube-system || true
    kubectl describe apiservice v1beta1.metrics.k8s.io || true
    exit 1
  fi

  sleep 5
done

echo "Waiting for application Deployment..."
kubectl rollout status \
  deployment/102783255-burn \
  --namespace "$NAMESPACE" \
  --timeout=180s

echo "Waiting for pod metrics..."
for attempt in $(seq 1 60); do
  if kubectl top pods --namespace "$NAMESPACE" >/dev/null 2>&1; then
    break
  fi

  if [ "$attempt" -eq 60 ]; then
    echo "ERROR: pod metrics did not become available" >&2
    kubectl get pods -n "$NAMESPACE" || true
    kubectl top nodes || true
    exit 1
  fi

  sleep 5
done

echo
echo "Bootstrap completed successfully."
echo

kubectl get nodes
kubectl get all --namespace "$NAMESPACE"
kubectl get hpa --namespace "$NAMESPACE"
kubectl describe quota 102783255-quota --namespace "$NAMESPACE"
kubectl top nodes
kubectl top pods --namespace "$NAMESPACE"
