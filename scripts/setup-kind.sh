#!/bin/bash
set -e

echo "🚀 Setting up Kind cluster for TD-pipeline with LocalStack S3..."

# Create Kind cluster
echo "Creating Kind cluster..."
kind create cluster --config kind-config.yaml --name td-pipeline

# Wait for cluster to be ready
echo "Waiting for cluster to be ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=300s

# Add Helm repositories
echo "Adding Helm repositories..."
helm repo add redpanda https://charts.redpanda.com/
helm repo add localstack https://localstack.github.io/helm-charts
helm repo update

echo "✅ Kind cluster setup complete!"
echo "Cluster info:"
kubectl cluster-info --context kind-td-pipeline
