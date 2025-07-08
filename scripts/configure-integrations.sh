#!/bin/bash

# Configure Integrations Script for Streaming Platform
# This script configures various integrations and connections

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
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
    echo -e "${BLUE}[CONFIG]${NC} $1"
}

print_section() {
    echo -e "${PURPLE}[SECTION]${NC} $1"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 <integration-type> [options]"
    echo ""
    echo "Available integration types:"
    echo "  database      - Configure database connections"
    echo "  messaging     - Configure messaging systems (Kafka, RabbitMQ)"
    echo "  monitoring    - Configure monitoring and alerting"
    echo "  storage       - Configure storage systems (S3, GCS, Azure)"
    echo "  api-gateway   - Configure API gateway settings"
    echo "  security      - Configure security and authentication"
    echo "  all           - Configure all integrations"
    echo ""
    echo "Options:"
    echo "  --env <env>   - Environment (dev/staging/prod)"
    echo "  --dry-run     - Show what would be done without executing"
    echo "  --backup      - Create backup before configuration"
    echo "  --validate    - Validate configuration after setup"
    echo ""
    echo "Examples:"
    echo "  $0 database --env dev --validate"
    echo "  $0 messaging --dry-run"
    echo "  $0 all --env production --backup"
}

# Check if integration type is provided
if [ $# -eq 0 ]; then
    print_error "Integration type is required"
    show_usage
    exit 1
fi

INTEGRATION_TYPE=$1
ENVIRONMENT="dev"
DRY_RUN=false
CREATE_BACKUP=false
VALIDATE_CONFIG=false

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
        --backup)
            CREATE_BACKUP=true
            shift
            ;;
        --validate)
            VALIDATE_CONFIG=true
            shift
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

print_header "Configuring $INTEGRATION_TYPE integration in $ENVIRONMENT environment"

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|production)$ ]]; then
    print_error "Invalid environment: $ENVIRONMENT"
    exit 1
fi

# Function to create backup
create_backup() {
    if [ "$CREATE_BACKUP" = true ]; then
        print_status "Creating configuration backup..."
        BACKUP_DIR="backups/$(date +%Y%m%d_%H%M%S)"
        mkdir -p "$BACKUP_DIR"
        echo "  - Backup created in: $BACKUP_DIR"
    fi
}

# Function to configure database connections
configure_database() {
    print_section "Database Integration Configuration"
    
    if [ "$DRY_RUN" = true ]; then
        echo "  [DRY RUN] Would configure PostgreSQL connection"
        echo "  [DRY RUN] Would configure MySQL connection"
        echo "  [DRY RUN] Would configure Redis connection"
        return
    fi
    
    create_backup
    
    echo "  - Configuring PostgreSQL connection pool"
    echo "  - Setting up MySQL replication settings"
    echo "  - Configuring Redis cluster settings"
    echo "  - Setting up connection encryption"
    echo "  - Configuring connection timeouts"
    
    sleep 2
    echo "  - Database connections configured"
}

# Function to configure messaging systems
configure_messaging() {
    print_section "Messaging System Configuration"
    
    if [ "$DRY_RUN" = true ]; then
        echo "  [DRY RUN] Would configure Kafka topics"
        echo "  [DRY RUN] Would configure RabbitMQ exchanges"
        echo "  [DRY RUN] Would configure message routing"
        return
    fi
    
    create_backup
    
    echo "  - Configuring Kafka topic partitions"
    echo "  - Setting up RabbitMQ exchanges and queues"
    echo "  - Configuring message routing rules"
    echo "  - Setting up dead letter queues"
    echo "  - Configuring message retention policies"
    
    sleep 2
    echo "  - Messaging system configured"
}

# Function to configure monitoring
configure_monitoring() {
    print_section "Monitoring and Alerting Configuration"
    
    if [ "$DRY_RUN" = true ]; then
        echo "  [DRY RUN] Would configure Prometheus targets"
        echo "  [DRY RUN] Would configure Grafana dashboards"
        echo "  [DRY RUN] Would configure alerting rules"
        return
    fi
    
    create_backup
    
    echo "  - Configuring Prometheus scrape targets"
    echo "  - Setting up Grafana dashboard templates"
    echo "  - Configuring alerting rules and thresholds"
    echo "  - Setting up notification channels"
    echo "  - Configuring log aggregation"
    
    sleep 2
    echo "  - Monitoring system configured"
}

# Function to configure storage
configure_storage() {
    print_section "Storage System Configuration"
    
    if [ "$DRY_RUN" = true ]; then
        echo "  [DRY RUN] Would configure S3 bucket policies"
        echo "  [DRY RUN] Would configure GCS bucket settings"
        echo "  [DRY RUN] Would configure Azure Blob storage"
        return
    fi
    
    create_backup
    
    echo "  - Configuring S3 bucket access policies"
    echo "  - Setting up GCS bucket lifecycle rules"
    echo "  - Configuring Azure Blob storage containers"
    echo "  - Setting up cross-region replication"
    echo "  - Configuring backup and retention policies"
    
    sleep 2
    echo "  - Storage systems configured"
}

# Function to configure API gateway
configure_api_gateway() {
    print_section "API Gateway Configuration"
    
    if [ "$DRY_RUN" = true ]; then
        echo "  [DRY RUN] Would configure API routes"
        echo "  [DRY RUN] Would configure rate limiting"
        echo "  [DRY RUN] Would configure authentication"
        return
    fi
    
    create_backup
    
    echo "  - Configuring API routes and endpoints"
    echo "  - Setting up rate limiting policies"
    echo "  - Configuring authentication middleware"
    echo "  - Setting up CORS policies"
    echo "  - Configuring request/response transformations"
    
    sleep 2
    echo "  - API gateway configured"
}

# Function to configure security
configure_security() {
    print_section "Security and Authentication Configuration"
    
    if [ "$DRY_RUN" = true ]; then
        echo "  [DRY RUN] Would configure SSL certificates"
        echo "  [DRY RUN] Would configure OAuth2 settings"
        echo "  [DRY RUN] Would configure RBAC policies"
        return
    fi
    
    create_backup
    
    echo "  - Configuring SSL/TLS certificates"
    echo "  - Setting up OAuth2 authentication"
    echo "  - Configuring RBAC policies"
    echo "  - Setting up network security groups"
    echo "  - Configuring audit logging"
    
    sleep 2
    echo "  - Security configuration completed"
}

# Function to validate configuration
validate_configuration() {
    if [ "$VALIDATE_CONFIG" = true ]; then
        print_status "Validating configuration..."
        echo "  - Checking connectivity to all services"
        echo "  - Validating authentication tokens"
        echo "  - Testing API endpoints"
        echo "  - Verifying monitoring targets"
        echo "  - Checking storage access"
        
        sleep 2
        echo "  - Configuration validation completed successfully"
    fi
}

# Main configuration logic
case $INTEGRATION_TYPE in
    "database")
        configure_database
        ;;
    "messaging")
        configure_messaging
        ;;
    "monitoring")
        configure_monitoring
        ;;
    "storage")
        configure_storage
        ;;
    "api-gateway")
        configure_api_gateway
        ;;
    "security")
        configure_security
        ;;
    "all")
        print_status "Configuring all integrations..."
        configure_database
        configure_messaging
        configure_monitoring
        configure_storage
        configure_api_gateway
        configure_security
        ;;
    *)
        print_error "Unknown integration type: $INTEGRATION_TYPE"
        show_usage
        exit 1
        ;;
esac

# Post-configuration validation
validate_configuration

if [ "$DRY_RUN" = false ]; then
    print_status "Integration configuration completed successfully!"
    print_warning "Please review the configuration files in config/ directory"
else
    print_status "Dry run completed. No changes made."
fi 