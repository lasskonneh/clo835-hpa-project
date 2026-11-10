#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="102783255-hpa"
QUOTA_NAME="102783255-quota"
TEMPLATE="manifests/05-quota-template.yaml"

QUOTA_PODS="${1:-6}"
QUOTA_CPU="${2:-1000m}"

if ! [[ "$QUOTA_PODS" =~ ^[0-9]+$ ]]; then
  echo "ERROR: pod quota must be a whole number"
  echo "Usage: ./apply-quota.sh [pod-count] [cpu-quota]"
  exit 1
fi

if ! [[ "$QUOTA_CPU" =~ ^[0-9]+m$ ]]; then
  echo "ERROR: CPU quota must use millicores, for example 1000m"
  echo "Usage: ./apply-quota.sh [pod-count] [cpu-quota]"
  exit 1
fi

TEMP_FILE="$(mktemp)"

sed \
  -e "s/__QUOTA_PODS__/${QUOTA_PODS}/g" \
  -e "s/__QUOTA_CPU__/${QUOTA_CPU}/g" \
  "$TEMPLATE" > "$TEMP_FILE"

kubectl apply -f "$TEMP_FILE"
rm -f "$TEMP_FILE"

kubectl describe quota "$QUOTA_NAME" -n "$NAMESPACE"
