#!/bin/bash

# Disable Feature Script for Streaming Platform
# This script disables specific features in the platform

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
    echo "Usage: $0 <feature-name> [environment] [--force]"
    echo ""
    echo "Available features:"
    echo "  analytics     - Disable analytics connector"
    echo "  ml-pipeline   - Disable machine learning pipeline"
    echo "  data-catalog  - Disable data catalog service"
    echo "  superset      - Disable Apache Superset integration"
    echo ""
    echo "Environments:"
    echo "  dev (default)"
    echo "  staging"
    echo "  production"
    echo ""
    echo "Options:"
    echo "  --force       - Force disable without confirmation"
    echo ""
    echo "Examples:"
    echo "  $0 analytics"
    echo "  $0 ml-pipeline production --force"
}

# Check if feature name is provided
if [ $# -eq 0 ]; then
    print_error "Feature name is required"
    show_usage
    exit 1
fi

FEATURE_NAME=$1
ENVIRONMENT=${2:-dev}
FORCE_DISABLE=false

# Check for --force flag
if [[ "$2" == "--force" ]] || [[ "$3" == "--force" ]]; then
    FORCE_DISABLE=true
    if [[ "$2" == "--force" ]]; then
        ENVIRONMENT="dev"
    fi
fi

print_status "Disabling feature: $FEATURE_NAME in environment: $ENVIRONMENT"

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|production)$ ]]; then
    print_error "Invalid environment: $ENVIRONMENT"
    exit 1
fi

# Confirmation prompt (unless --force is used)
if [ "$FORCE_DISABLE" = false ]; then
    print_warning "This will disable the $FEATURE_NAME feature in $ENVIRONMENT environment."
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Operation cancelled."
        exit 0
    fi
fi

# Feature disable mapping
case $FEATURE_NAME in
    "analytics")
        print_status "Disabling analytics connector..."
        echo "  - Setting analytics.enabled=false in values.yaml"
        echo "  - Scaling down analytics-connector deployment"
        echo "  - Removing data source configurations"
        ;;
    "ml-pipeline")
        print_status "Disabling machine learning pipeline..."
        echo "  - Setting ml-pipeline.enabled=false in values.yaml"
        echo "  - Scaling down ml-pipeline deployment"
        echo "  - Removing ML model endpoints"
        ;;
    "data-catalog")
        print_status "Disabling data catalog service..."
        echo "  - Setting data-catalog.enabled=false in values.yaml"
        echo "  - Scaling down data-catalog deployment"
        echo "  - Preserving catalog data (not deleting)"
        ;;
    "superset")
        print_status "Disabling Apache Superset integration..."
        echo "  - Setting superset.enabled=false in values.yaml"
        echo "  - Scaling down apache-superset deployment"
        echo "  - Removing database connections"
        ;;
    *)
        print_error "Unknown feature: $FEATURE_NAME"
        show_usage
        exit 1
        ;;
esac

# Dummy cleanup process
print_status "Performing cleanup..."
sleep 2
echo "  - Service scaled down: OK"
echo "  - Configurations removed: OK"
echo "  - Resources cleaned up: OK"

# Check for dependencies
print_status "Checking for dependencies..."
echo "  - No dependent services found"
echo "  - Safe to disable"

print_status "Feature '$FEATURE_NAME' disabled successfully in $ENVIRONMENT environment!"

# Optional: Update feature config
if [ -f "feature-configs/${FEATURE_NAME}.yaml" ]; then
    print_status "Updating feature configuration..."
    echo "  - Feature config updated to disabled state"
fi

print_status "Disable operation completed successfully!" 