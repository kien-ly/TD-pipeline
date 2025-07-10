#!/bin/bash
set -e

ENV=${1:-dev}
CHART_DIR=$(dirname "$0")/..
VALUES_FILE="$CHART_DIR/values-$ENV.yaml"

if ! command -v yq &> /dev/null; then
  echo "[ERROR] yq is required. Install with: brew install yq (macOS) or pip install yq (Python)" >&2
  exit 1
fi

NAMESPACE=$(yq '.global.namespace' "$VALUES_FILE")

echo "Checking pod status in $NAMESPACE..."
kubectl get pods -n $NAMESPACE

echo "\nRecent logs for Redpanda:"
kubectl logs -l app=redpanda -n $NAMESPACE --tail=20 || true

echo "\nRecent logs for Debezium:"
kubectl logs -l app=debezium -n $NAMESPACE --tail=20 || true

echo "\nRecent logs for Kafka Connect:"
kubectl logs -l app=kafka-connect -n $NAMESPACE --tail=20 || true

echo "\nRecent logs for Flink JobManager:"
kubectl logs -l app=flink-jobmanager -n $NAMESPACE --tail=20 || true

echo "[INFO] Implement connection validation logic here (e.g., test DB, S3, Kafka, etc.)" 