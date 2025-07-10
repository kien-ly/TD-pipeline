#!/bin/bash
set -e

ENV=$1
if [ -z "$ENV" ]; then
  echo "❌ Usage: $0 <dev|prod|staging>"
  exit 1
fi

case $ENV in
  dev)
    NS="data-platform-dev"
    VALUES="values-dev.yaml"
    ;;
  prod)
    NS="data-platform-prod"
    VALUES="values-prod.yaml"
    ;;
  staging)
    NS="data-platform-staging"
    VALUES="values-staging.yaml"
    ;;
  *)
    echo "❌ Unknown environment: $ENV"
    exit 2
    ;;
esac

CHART_DIR=$(dirname "$0")/..
VALUES_FILE="$CHART_DIR/$VALUES"

if ! command -v yq &> /dev/null; then
  echo "[ERROR] yq is required. Install with: brew install yq (macOS) or pip install yq (Python)" >&2
  exit 1
fi

helm dependency update "$CHART_DIR"
helm upgrade --install data-platform "$CHART_DIR" \
  -f "$CHART_DIR/values.yaml" \
  -f "$VALUES_FILE" \
  --namespace "$NS" --create-namespace 