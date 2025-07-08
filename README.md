# TD-Pipeline: Multi-Environment Data Engineering Pipeline

A **production-ready** data engineering pipeline with PostgreSQL CDC, Redpanda, Apache Flink, and AWS S3 storage, supporting multiple environments (dev, staging, prod).

## 🏗️ Architecture

```
PostgreSQL (External) → Debezium → Redpanda → Apache Flink → AWS S3 (Parquet)
```

### Data Flow
1. **PostgreSQL** - External database with logical replication enabled
2. **Debezium** - Captures database changes (CDC) and publishes to Kafka
3. **Redpanda** - High-performance Kafka-compatible streaming platform
4. **Apache Flink** - Stream processing for real-time ETL and transformations
5. **AWS S3** - Data lake storage with Parquet format and time-based partitioning

## 🚀 Quick Start

### Prerequisites

- Kubernetes cluster (1.24+)
- Helm 3.x
- kubectl configured
- Maven 3.6+ (for Flink job)
- Docker (for building images)
- AWS CLI configured
- kubeseal (for Sealed Secrets)

### 1. Setup Environment

```bash
# Clone repository
git clone https://github.com/kien-ly/TD-pipeline.git
cd td-pipeline

# Make scripts executable
chmod +x scripts/*.sh
```

### 2. Configure Local PostgreSQL

Set up your local PostgreSQL database for CDC:

```sql
-- Enable logical replication (in postgresql.conf)
-- wal_level = logical
-- max_replication_slots = 4
-- max_wal_senders = 4

-- Restart PostgreSQL service
sudo systemctl restart postgresql

-- Create database and user
CREATE DATABASE td_pipeline;
CREATE USER debezium WITH REPLICATION LOGIN PASSWORD 'your-secure-password';
GRANT ALL PRIVILEGES ON DATABASE td_pipeline TO debezium;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO debezium;
GRANT USAGE ON SCHEMA public TO debezium;

-- Create test table
CREATE TABLE customers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255),
    email VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 3. Setup AWS S3

```bash
# Create S3 buckets
aws s3 mb s3://staging-td-pipeline-data
aws s3 mb s3://staging-td-pipeline-checkpoints
aws s3 mb s3://prod-td-pipeline-data
aws s3 mb s3://prod-td-pipeline-checkpoints

# Create IAM policy for S3 access
aws iam create-policy \
    --policy-name TD-Pipeline-S3-Policy \
    --policy-document '{
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": [
                    "s3:GetObject",
                    "s3:PutObject",
                    "s3:DeleteObject",
                    "s3:ListBucket"
                ],
                "Resource": [
                    "arn:aws:s3:::*-td-pipeline-data",
                    "arn:aws:s3:::*-td-pipeline-data/*",
                    "arn:aws:s3:::*-td-pipeline-checkpoints",
                    "arn:aws:s3:::*-td-pipeline-checkpoints/*"
                ]
            }
        ]
    }'
```

### 4. Install Sealed Secrets Controller

```bash
# Install Sealed Secrets Controller
helm repo add sealed-secrets https://bitnami-labs.github.io/sealed-secrets
helm repo update
helm install sealed-secrets-controller sealed-secrets/sealed-secrets \
    --namespace kube-system \
    --create-namespace
```

### 5. Configure Secrets

```bash
# Setup secrets for staging environment
./scripts/setup-secrets.sh staging

# Setup secrets for production environment
./scripts/setup-secrets.sh prod
```

### 6. Build Flink Job

```bash
# Build the Flink CDC processor job
./scripts/build-flink-job.sh
```

### 7. Deploy to Staging

```bash
# Deploy to staging environment
./scripts/deploy.sh staging
```

### 8. Deploy to Production

```bash
# Deploy to production environment
./scripts/deploy.sh prod
```

## 🌍 Environment Configuration

### Available Environments

- **dev**: Local development with minimal resources
- **staging**: Pre-production environment with AWS S3
- **prod**: Production environment with high availability

### Environment-Specific Values

Each environment has its own configuration file:

- `environments/values-dev.yaml`
- `environments/values-staging.yaml`
- `environments/values-prod.yaml`

### Key Differences

| Component | Dev | Staging | Production |
|-----------|-----|---------|------------|
| Redpanda Replicas | 1 | 3 | 5 |
| Flink TaskManagers | 1 | 3 | 6 |
| Kafka Connect Replicas | 1 | 2 | 3 |
| Storage Size | 10Gi | 50Gi | 100Gi |
| Resource Limits | Small | Medium | Large |

## 🔐 Secrets Management

### Using Sealed Secrets

Secrets are managed using Sealed Secrets for secure Git storage:

```bash
# Create a new secret
kubectl create secret generic my-secret \
    --from-literal=username=admin \
    --from-literal=password=secret123 \
    --dry-run=client -o yaml | \
    kubeseal --controller-namespace kube-system --format yaml > my-sealed-secret.yaml

# Apply sealed secret
kubectl apply -f my-sealed-secret.yaml
```

### Required Secrets

Each environment requires the following secrets:

#### PostgreSQL Credentials
```bash
# Create PostgreSQL credentials
kubectl create secret generic postgres-credentials \
    --from-literal=username=debezium \
    --from-literal=password=your-secure-password \
    --dry-run=client -o yaml | \
    kubeseal --format yaml > secrets/staging/postgres-credentials.yaml
```

#### AWS Credentials
```bash
# Create AWS credentials
kubectl create secret generic aws-credentials \
    --from-literal=access-key-id=your-aws-access-key \
    --from-literal=secret-access-key=your-aws-secret-key \
    --dry-run=client -o yaml | \
    kubeseal --format yaml > secrets/staging/aws-credentials.yaml
```

### AWS IAM Roles (Production Recommendation)

For production environments, use IAM roles with IRSA (IAM Roles for Service Accounts):

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:PutObject",
                "s3:DeleteObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::your-bucket-name",
                "arn:aws:s3:::your-bucket-name/*"
            ]
        }
    ]
}
```

## 🔧 Configuration

### PostgreSQL Setup

Configure your external PostgreSQL database:

```sql
-- Enable logical replication
ALTER SYSTEM SET wal_level = logical;
ALTER SYSTEM SET max_replication_slots = 4;
ALTER SYSTEM SET max_wal_senders = 4;

-- Create replication user
CREATE USER debezium WITH REPLICATION LOGIN PASSWORD 'your-password';
GRANT SELECT ON ALL TABLES IN SCHEMA public TO debezium;
GRANT USAGE ON SCHEMA public TO debezium;

-- Create test table
CREATE TABLE customers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255),
    email VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Kafka Connect Connectors

Connectors are automatically configured via Helm templates:

- **Debezium PostgreSQL**: Captures database changes
- **S3 Sink**: Writes data to S3 in Parquet format

### Flink Job Configuration

The Flink job is configured to:

- Read from Kafka topics
- Process CDC events
- Write to S3 with time-based partitioning
- Handle checkpointing and recovery

## 📊 Monitoring

### Health Checks

```bash
# Check pod status
kubectl get pods -n td-pipeline-staging

# Check connector status
kubectl port-forward -n td-pipeline-staging svc/kafka-connect 8083:8083
curl http://localhost:8083/connectors

# Check Flink job status
kubectl port-forward -n td-pipeline-staging svc/flink-jobmanager 8081:8081
# Visit http://localhost:8081
```

### Logs

```bash
# View Kafka Connect logs
kubectl logs -n td-pipeline-staging deployment/kafka-connect

# View Flink logs
kubectl logs -n td-pipeline-staging deployment/flink-jobmanager
kubectl logs -n td-pipeline-staging deployment/flink-taskmanager

# View Redpanda logs
kubectl logs -n td-pipeline-staging statefulset/redpanda
```

### Metrics and Dashboards

The pipeline exposes metrics through:

- **Kafka Connect**: JMX metrics on port 9404
- **Flink**: Web UI on port 8081 with job metrics
- **Redpanda**: Prometheus metrics on port 9644

## 🚨 Troubleshooting

### Common Issues

#### 1. Secrets not found
```bash
# Check if secrets exist
kubectl get secrets -n td-pipeline-staging

# Recreate secrets
./scripts/setup-secrets.sh staging
```

#### 2. Connector fails to start
```bash
# Check connector logs
kubectl logs -n td-pipeline-staging deployment/kafka-connect

# Restart connector
kubectl rollout restart deployment/kafka-connect -n td-pipeline-staging
```

#### 3. Flink job fails
```bash
# Check Flink logs
kubectl logs -n td-pipeline-staging deployment/flink-jobmanager

# Restart Flink
kubectl rollout restart deployment/flink-jobmanager -n td-pipeline-staging
```

### Database Connection Issues

```bash
# Test PostgreSQL connection
kubectl run postgres-client --image=postgres:15 --rm -it --restart=Never -- \
    psql -h your-db-host -U postgres -d source_db
```

### S3 Connection Issues

```bash
# Test S3 access
kubectl run aws-cli --image=amazon/aws-cli --rm -it --restart=Never -- \
    s3 ls s3://your-bucket-name
```

### Debugging Steps

1. **Check Resource Limits**: Ensure pods have sufficient memory and CPU
2. **Verify Network Connectivity**: Test connections between components
3. **Check Logs**: Review application logs for specific error messages
4. **Monitor Metrics**: Use Kubernetes dashboard or monitoring tools

## 🔄 CI/CD Integration

### GitHub Actions Example

```yaml
name: Deploy TD-Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v2
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: us-east-1
    
    - name: Setup Helm
      uses: azure/setup-helm@v3
      with:
        version: '3.10.0'
    
    - name: Setup kubectl
      uses: azure/setup-kubectl@v3
      with:
        version: '1.24.0'
    
    - name: Build Flink job
      run: |
        cd flink-jobs
        mvn clean package
        docker build -t td-pipeline-flink:${{ github.sha }} .
    
    - name: Deploy to staging
      if: github.ref == 'refs/heads/develop'
      run: |
        ./scripts/deploy.sh staging
    
    - name: Deploy to production
      if: github.ref == 'refs/heads/main'
      run: |
        ./scripts/deploy.sh prod
```

### GitLab CI Example

```yaml
stages:
  - build
  - test
  - deploy

variables:
  DOCKER_DRIVER: overlay2
  MAVEN_OPTS: "-Dmaven.repo.local=.m2/repository"

build-flink-job:
  stage: build
  script:
    - cd flink-jobs
    - mvn clean package
    - docker build -t $CI_REGISTRY_IMAGE/flink:$CI_COMMIT_SHA .
    - docker push $CI_REGISTRY_IMAGE/flink:$CI_COMMIT_SHA

deploy-staging:
  stage: deploy
  script:
    - ./scripts/deploy.sh staging
  only:
    - develop

deploy-production:
  stage: deploy
  script:
    - ./scripts/deploy.sh prod
  only:
    - main
  when: manual
```

## 📈 Scaling

### Horizontal Scaling

Adjust replicas in environment values:

```yaml
# environments/values-prod.yaml
global:
  redpanda:
    replicas: 5
  flink:
    taskmanager:
      replicas: 10
  kafkaConnect:
    replicas: 3
```

### Vertical Scaling

Increase resources:

```yaml
# environments/values-prod.yaml
global:
  resources:
    large:
      requests:
        memory: 4Gi
        cpu: 2000m
      limits:
        memory: 8Gi
        cpu: 4000m
```

### Auto-scaling

Configure HPA (Horizontal Pod Autoscaler):

```yaml
# charts/flink/templates/hpa.yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: flink-taskmanager-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: flink-taskmanager
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

## 🧪 Testing

### Unit Tests

```bash
# Run Flink job tests
cd flink-jobs
mvn test
```

### Integration Tests

```bash
# Test database connectivity
./scripts/test-postgres.sh

# Test S3 connectivity
./scripts/test-s3.sh

# Test end-to-end pipeline
./scripts/test-pipeline.sh staging
```

### Performance Tests

```bash
# Load test with sample data
./scripts/load-test.sh staging 1000
```

## 🔍 Data Validation

### Data Quality Checks

The pipeline includes built-in data validation:

```java
// Example validation in Flink job
public class DataValidator {
    public boolean validateRecord(JsonNode record) {
        return record.has("id") && 
               record.has("timestamp") && 
               record.get("id").asInt() > 0;
    }
}
```

### Schema Evolution

Supports schema evolution through:

- **Debezium schema registry** integration
- **Parquet schema evolution** in S3
- **Flink state migration** for job updates

## 🧹 Cleanup

### Remove Staging Deployment

```bash
# Remove staging deployment
helm uninstall td-pipeline-staging -n td-pipeline-staging

# Remove namespace
kubectl delete namespace td-pipeline-staging
```

### Remove Production Deployment

```bash
# Remove production deployment
helm uninstall td-pipeline-prod -n td-pipeline-prod

# Remove namespace
kubectl delete namespace td-pipeline-prod
```

### Remove Sealed Secrets Controller

```bash
# Remove sealed secrets controller (if not needed)
helm uninstall sealed-secrets-controller -n kube-system
```

### Clean Up AWS Resources

```bash
# Remove S3 buckets (be careful!)
aws s3 rb s3://staging-td-pipeline-data --force
aws s3 rb s3://staging-td-pipeline-checkpoints --force
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Test in dev environment
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Submit a pull request

### Development Guidelines

- Follow the existing code style
- Add tests for new features
- Update documentation
- Ensure all environments work correctly

## 📂 Repository Structure

```
td-pipeline/
├── charts/                          # Helm charts
│   ├── td-pipeline/                 # Main umbrella chart
│   │   ├── Chart.yaml
│   │   ├── values.yaml             # Default values
│   │   └── templates/
│   │       ├── _helpers.tpl
│   │       └── sealed-secrets.yaml
│   ├── redpanda/                   # Redpanda chart
│   │   ├── Chart.yaml
│   │   ├── values.yaml
│   │   └── templates/
│   ├── kafka-connect/              # Kafka Connect chart
│   │   ├── Chart.yaml
│   │   ├── values.yaml
│   │   └── templates/
│   ├── flink/                      # Flink chart
│   │   ├── Chart.yaml
│   │   ├── values.yaml
│   │   └── templates/
│   └── postgres/                   # PostgreSQL chart (external config)
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
├── environments/                   # Environment-specific configurations
│   ├── values-dev.yaml
│   ├── values-staging.yaml
│   └── values-prod.yaml
├── secrets/                        # Sealed secrets by environment
│   ├── dev/
│   │   ├── postgres-credentials.yaml
│   │   └── aws-credentials.yaml
│   ├── staging/
│   │   ├── postgres-credentials.yaml
│   │   └── aws-credentials.yaml
│   └── prod/
│       ├── postgres-credentials.yaml
│       └── aws-credentials.yaml
├── flink-jobs/                     # Flink job source code
│   ├── src/
│   │   └── main/
│   │       └── java/
│   │           └── CDCProcessor.java
│   ├── pom.xml
│   └── Dockerfile
├── scripts/                        # Deployment and utility scripts
│   ├── deploy.sh
│   ├── setup-secrets.sh
│   ├── build-flink-job.sh
│   ├── test-postgres.sh
│   ├── test-s3.sh
│   ├── test-pipeline.sh
│   └── load-test.sh
├── docs/                          # Additional documentation
│   ├── architecture.md
│   ├── deployment.md
│   └── troubleshooting.md
├── config/                        # Configuration files
│   └── api-gateways/
├── connectors/                    # Kafka Connect connector configs
├── .github/                       # GitHub Actions workflows
│   └── workflows/
│       └── deploy.yml
├── .gitignore
├── Chart.yaml                     # Root chart metadata
├── requirements.yaml              # Chart dependencies
├── values-local.yaml              # Local development values
├── values.yaml                    # Default values
└── README.md                      # This file
```

## 🎯 Features

This complete refactored pipeline provides:

✅ **Multi-environment support** with proper values templating  
✅ **AWS S3 integration** with Kafka Connect S3 sink connector  
✅ **Secure secrets management** using Sealed Secrets  
✅ **External PostgreSQL configuration** without containers  
✅ **Fully templated Helm charts** with no hardcoded values  
✅ **Production-ready Flink jobs** with proper checkpointing  
✅ **Comprehensive deployment scripts** for easy automation  
✅ **Monitoring and troubleshooting** guidelines  
✅ **CI/CD integration** with GitHub Actions and GitLab CI  
✅ **Auto-scaling capabilities** with HPA support  
✅ **Data validation and quality checks**  
✅ **Schema evolution support**  

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.[1]

**Note**: This README reflects the completely refactored and production-ready version of the TD-Pipeline. The original repository structure has been enhanced with proper Helm templating, AWS S3 integration, external PostgreSQL support, and comprehensive deployment automation.

[1] https://github.com/kien-ly/TD-pipeline