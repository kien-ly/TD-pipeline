#!/bin/bash
# scripts/deploy.sh

set -e

ENVIRONMENT=${1:-staging}
NAMESPACE="td-pipeline-${ENVIRONMENT}"

echo "Deploying TD-Pipeline to ${ENVIRONMENT} environment..."

# Create namespace if it doesn't exist
kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

# Install Sealed Secrets Controller (if not already installed)
if ! kubectl get crd sealedsecrets.bitnami.com &> /dev/null; then
    echo "Installing Sealed Secrets Controller..."
    helm repo add sealed-secrets https://bitnami-labs.github.io/sealed-secrets
    helm repo update
    helm install sealed-secrets-controller sealed-secrets/sealed-secrets \
        --namespace kube-system \
        --create-namespace
fi

# Deploy secrets
echo "Deploying secrets..."
kubectl apply -f secrets/${ENVIRONMENT}/ -n ${NAMESPACE}

# Deploy the main application
echo "Deploying TD-Pipeline..."
helm upgrade --install td-pipeline-${ENVIRONMENT} charts/td-pipeline \
    --namespace ${NAMESPACE} \
    --values environments/values-${ENVIRONMENT}.yaml \
    --wait \
    --timeout 300s

echo "Deployment completed successfully!"
echo "Checking deployment status..."
kubectl get pods -n ${NAMESPACE}
