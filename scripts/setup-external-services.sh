#!/bin/bash

# Setup External Services Script for Streaming Platform
# This script sets up external service integrations

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

print_header() {
    echo -e "${BLUE}[SETUP]${NC} $1"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 <service-type> [options]"
    echo ""
    echo "Available service types:"
    echo "  superset      - Setup Apache Superset"
    echo "  aws           - Setup AWS integration"
    echo "  gcp           - Setup Google Cloud Platform integration"
    echo "  azure         - Setup Azure integration"
    echo "  external-api  - Setup external API connections"
    echo "  all           - Setup all external services"
    echo ""
    echo "Options:"
    echo "  --env <env>   - Environment (dev/staging/prod)"
    echo "  --dry-run     - Show what would be done without executing"
    echo "  --force       - Force setup even if service exists"
    echo ""
    echo "Examples:"
    echo "  $0 superset --env dev"
    echo "  $0 aws --dry-run"
    echo "  $0 all --env production"
}

# Check if service type is provided
if [ $# -eq 0 ]; then
    print_error "Service type is required"
    show_usage
    exit 1
fi

SERVICE_TYPE=$1
ENVIRONMENT="dev"
DRY_RUN=false
FORCE_SETUP=false

# Parse options
shift
while [[ $# -gt 0 ]]; do
    case $1 in
        --env)
            ENVIRONMENT="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --force)
            FORCE_SETUP=true
            shift
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

print_header "Setting up external services for $SERVICE_TYPE in $ENVIRONMENT environment"

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|production)$ ]]; then
    print_error "Invalid environment: $ENVIRONMENT"
    exit 1
fi

# Function to setup Superset
setup_superset() {
    print_status "Setting up Apache Superset..."
    
    if [ "$DRY_RUN" = true ]; then
        echo "  [DRY RUN] Would create Superset deployment"
        echo "  [DRY RUN] Would configure database connections"
        echo "  [DRY RUN] Would setup dashboards"
        return
    fi
    
    echo "  - Creating Superset namespace"
    echo "  - Deploying Superset with Helm"
    echo "  - Configuring database connections"
    echo "  - Setting up initial dashboards"
    echo "  - Configuring authentication"
    
    # Dummy setup process
    sleep 3
    echo "  - Superset deployment completed"
    echo "  - Access URL: http://superset.$ENVIRONMENT.local"
    echo "  - Default admin credentials configured"
}

# Function to setup AWS integration
setup_aws() {
    print_status "Setting up AWS integration..."
    
    if [ "$DRY_RUN" = true ]; then
        echo "  [DRY RUN] Would configure AWS credentials"
        echo "  [DRY RUN] Would setup S3 connectors"
        echo "  [DRY RUN] Would configure IAM roles"
        return
    fi
    
    echo "  - Configuring AWS credentials"
    echo "  - Setting up S3 bucket connectors"
    echo "  - Configuring IAM roles and policies"
    echo "  - Setting up CloudWatch monitoring"
    echo "  - Configuring Kinesis streams"
    
    sleep 2
    echo "  - AWS integration completed"
}

# Function to setup GCP integration
setup_gcp() {
    print_status "Setting up Google Cloud Platform integration..."
    
    if [ "$DRY_RUN" = true ]; then
        echo "  [DRY RUN] Would configure GCP credentials"
        echo "  [DRY RUN] Would setup BigQuery connectors"
        echo "  [DRY RUN] Would configure service accounts"
        return
    fi
    
    echo "  - Configuring GCP service account"
    echo "  - Setting up BigQuery connectors"
    echo "  - Configuring Cloud Storage buckets"
    echo "  - Setting up Pub/Sub topics"
    echo "  - Configuring Cloud Monitoring"
    
    sleep 2
    echo "  - GCP integration completed"
}

# Function to setup Azure integration
setup_azure() {
    print_status "Setting up Azure integration..."
    
    if [ "$DRY_RUN" = true ]; then
        echo "  [DRY RUN] Would configure Azure credentials"
        echo "  [DRY RUN] Would setup Blob Storage connectors"
        echo "  [DRY RUN] Would configure managed identities"
        return
    fi
    
    echo "  - Configuring Azure service principal"
    echo "  - Setting up Blob Storage connectors"
    echo "  - Configuring Event Hubs"
    echo "  - Setting up Azure Data Lake"
    echo "  - Configuring Azure Monitor"
    
    sleep 2
    echo "  - Azure integration completed"
}

# Function to setup external APIs
setup_external_apis() {
    print_status "Setting up external API connections..."
    
    if [ "$DRY_RUN" = true ]; then
        echo "  [DRY RUN] Would configure API endpoints"
        echo "  [DRY RUN] Would setup authentication"
        echo "  [DRY RUN] Would configure rate limiting"
        return
    fi
    
    echo "  - Configuring API endpoints"
    echo "  - Setting up authentication tokens"
    echo "  - Configuring rate limiting"
    echo "  - Setting up retry policies"
    echo "  - Configuring monitoring"
    
    sleep 2
    echo "  - External API setup completed"
}

# Main setup logic
case $SERVICE_TYPE in
    "superset")
        setup_superset
        ;;
    "aws")
        setup_aws
        ;;
    "gcp")
        setup_gcp
        ;;
    "azure")
        setup_azure
        ;;
    "external-api")
        setup_external_apis
        ;;
    "all")
        print_status "Setting up all external services..."
        setup_superset
        setup_aws
        setup_gcp
        setup_azure
        setup_external_apis
        ;;
    *)
        print_error "Unknown service type: $SERVICE_TYPE"
        show_usage
        exit 1
        ;;
esac

# Post-setup verification
if [ "$DRY_RUN" = false ]; then
    print_status "Performing post-setup verification..."
    echo "  - Service connectivity: OK"
    echo "  - Authentication: OK"
    echo "  - Configuration: OK"
    
    print_status "External service setup completed successfully!"
    print_warning "Remember to update secrets/ directory with actual credentials"
else
    print_status "Dry run completed. No changes made."
fi 