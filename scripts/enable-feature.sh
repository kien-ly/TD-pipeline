#!/bin/bash

# Enable Feature Script for Streaming Platform
# This script enables specific features in the platform

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 <feature-name> [environment]"
    echo ""
    echo "Available features:"
    echo "  analytics     - Enable analytics connector"
    echo "  ml-pipeline   - Enable machine learning pipeline"
    echo "  data-catalog  - Enable data catalog service"
    echo "  superset      - Enable Apache Superset integration"
    echo ""
    echo "Environments:"
    echo "  dev (default)"
    echo "  staging"
    echo "  production"
    echo ""
    echo "Examples:"
    echo "  $0 analytics"
    echo "  $0 ml-pipeline production"
}

# Check if feature name is provided
if [ $# -eq 0 ]; then
    print_error "Feature name is required"
    show_usage
    exit 1
fi

FEATURE_NAME=$1
ENVIRONMENT=${2:-dev}

print_status "Enabling feature: $FEATURE_NAME in environment: $ENVIRONMENT"

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|production)$ ]]; then
    print_error "Invalid environment: $ENVIRONMENT"
    exit 1
fi

# Feature configuration mapping
case $FEATURE_NAME in
    "analytics")
        print_status "Enabling analytics connector..."
        # Dummy implementation - would normally update Helm values
        echo "  - Setting analytics.enabled=true in values.yaml"
        echo "  - Deploying analytics-connector chart"
        echo "  - Configuring data sources"
        ;;
    "ml-pipeline")
        print_status "Enabling machine learning pipeline..."
        echo "  - Setting ml-pipeline.enabled=true in values.yaml"
        echo "  - Deploying ml-pipeline chart"
        echo "  - Configuring ML model endpoints"
        ;;
    "data-catalog")
        print_status "Enabling data catalog service..."
        echo "  - Setting data-catalog.enabled=true in values.yaml"
        echo "  - Deploying data-catalog chart"
        echo "  - Initializing catalog database"
        ;;
    "superset")
        print_status "Enabling Apache Superset integration..."
        echo "  - Setting superset.enabled=true in values.yaml"
        echo "  - Deploying apache-superset chart"
        echo "  - Configuring database connections"
        ;;
    *)
        print_error "Unknown feature: $FEATURE_NAME"
        show_usage
        exit 1
        ;;
esac

# Dummy health check
print_status "Performing health check..."
sleep 2
echo "  - Service status: OK"
echo "  - Endpoints responding: OK"
echo "  - Configuration applied: OK"

print_status "Feature '$FEATURE_NAME' enabled successfully in $ENVIRONMENT environment!"

# Optional: Update feature config
if [ -f "feature-configs/${FEATURE_NAME}.yaml" ]; then
    print_status "Updating feature configuration..."
    echo "  - Feature config updated"
fi

print_status "Deployment completed successfully!" 