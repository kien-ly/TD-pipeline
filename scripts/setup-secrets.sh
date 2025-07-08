#!/bin/bash
set -e

ENV="${1:-staging}"
NAMESPACE="td-pipeline-${ENV}"

echo "🔐 Setting up secrets for ${ENV} environment..."

# Check if environment secrets exist
if [[ ! -d "secrets/${ENV}" ]]; then
    echo "❌ Secrets directory not found: secrets/${ENV}"
    exit 1
fi

# Install kubeseal if not present
if ! command -v kubeseal &> /dev/null; then
    echo "Installing kubeseal..."
    KUBESEAL_VERSION="0.24.0"
    curl -OL "https://github.com/bitnami-labs/sealed-secrets/releases/download/v${KUBESEAL_VERSION}/kubeseal-${KUBESEAL_VERSION}-linux-amd64.tar.gz"
    tar -xzf "kubeseal-${KUBESEAL_VERSION}-linux-amd64.tar.gz"
    sudo install -m 755 kubeseal /usr/local/bin/kubeseal
    rm -f "kubeseal-${KUBESEAL_VERSION}-linux-amd64.tar.gz" kubeseal
fi

# Wait for sealed-secrets controller to be ready
echo "Waiting for sealed-secrets controller..."
kubectl wait --for=condition=Available deployment/sealed-secrets-controller \
    --namespace kube-system --timeout=300s

# Create sealed secrets for each secret file
for secret_file in secrets/${ENV}/*.yaml; do
    if [[ -f "$secret_file" ]]; then
        echo "Processing secret: $(basename "$secret_file")"
        
        # Create sealed secret
        kubectl create secret generic temp-secret \
            --from-file="$secret_file" \
            --dry-run=client -o yaml | \
        kubeseal --controller-namespace kube-system \
            --controller-name sealed-secrets-controller \
            --format yaml > "/tmp/sealed-$(basename "$secret_file")"
        
        # Apply sealed secret
        kubectl apply -f "/tmp/sealed-$(basename "$secret_file")" -n "${NAMESPACE}"
        
        # Clean up
        rm -f "/tmp/sealed-$(basename "$secret_file")"
    fi
done

echo "✅ Secrets setup completed for ${ENV} environment"
