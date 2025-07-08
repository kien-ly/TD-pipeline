#!/bin/bash
set -e

echo "🚀 Deploying TD-pipeline to Kind cluster..."

# Create namespace
kubectl create namespace td-pipeline --dry-run=client -o yaml | kubectl apply -f -

# Apply secrets
echo "Applying secrets..."
kubectl apply -f secrets/ -n td-pipeline

# Install Helm dependencies
echo "Installing Helm dependencies..."
helm dependency update

# Deploy the pipeline
echo "Deploying pipeline..."
helm upgrade --install td-pipeline . \
  -f values-local.yaml \
  -n td-pipeline \
  --timeout 10m \
  --wait

echo "✅ Deployment complete!"

# Show deployed resources
echo "📊 Deployed resources:"
kubectl get all -n td-pipeline

echo "🌐 Access URLs:"
echo "- Flink UI: http://localhost:8081"
echo "- Redpanda Console: http://localhost:8082"
echo "- MinIO Console: http://localhost:9001"
echo "- Kafka Connect: http://localhost:8083"
