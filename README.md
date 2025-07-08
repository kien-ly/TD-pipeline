# TD-Pipeline: Multi-Environment Data Engineering Pipeline

Production-ready data engineering pipeline with PostgreSQL CDC, Redpanda, Apache Flink, and AWS S3 storage, supporting multiple environments (dev, staging, prod).

## 🏗️ Architecture

PostgreSQL (External) → Debezium → Redpanda → Apache Flink → AWS S3 (Parquet)


## 🚀 Quick Start

### Prerequisites
- Kubernetes cluster (1.24+)
- Helm 3.x
- kubectl configured
- Maven 3.6+ (for Flink job)
- Docker (for building images)

### 1. Setup Environment
Clone repository
git clone <repository-url>
cd td-pipeline

Make scripts executable
chmod +x scripts/*.sh


### 2. Configure Secrets
Update the secrets for your target environment:


### 2. Configure Secrets
Update the secrets for your target environment:


### 3. Deploy to Staging
Deploy to staging environment
./scripts/deploy.sh staging

### 4. Deploy to Production
Deploy to production environment
./scripts/deploy.sh prod


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

Create a new secret
kubectl create secret generic my-secret
--from-literal=username=admin
--from-literal=password=secret123
--dry-run=client -o yaml |
kubeseal --controller-namespace kube-system
--format yaml > my-sealed-secret.yaml

Apply sealed secret
kubectl apply -f my-sealed-secret.yaml


### AWS Credentials
For staging/production, use IAM roles with IRSA (IAM Roles for Service Accounts):

Example IAM policy for S3 access
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
Check pod status
kubectl get pods -n td-pipeline-staging

Check connector status
kubectl port-forward -n td-pipeline-staging svc/kafka-connect 8083:8083
curl http://localhost:8083/connectors

Check Flink job status
kubectl port-forward -n td-pipeline-staging svc/flink-jobmanager 8081:8081

Visit http://localhost:8081


### Logs
View Kafka Connect logs
kubectl logs -n td-pipeline-staging deployment/kafka-connect

View Flink logs
kubectl logs -n td-pipeline-staging deployment/flink-jobmanager
kubectl logs -n td-pipeline-staging deployment/flink-taskmanager


## 🚨 Troubleshooting

### Common Issues

1. **Secrets not found**
Check if secrets exist
kubectl get secrets -n td-pipeline-staging

Recreate secrets
./scripts/setup-secrets.sh staging


2. **Connector fails to start**
Check connector logs
kubectl logs -n td-pipeline-staging deployment/kafka-connect

Restart connector
kubectl rollout restart deployment/kafka-connect -n td-pipeline-staging


3. **Flink job fails**
Check Flink logs
kubectl logs -n td-pipeline-staging deployment/flink-jobmanager

Restart Flink
kubectl rollout restart deployment/flink-jobmanager -n td-pipeline-staging


### Database Connection Issues
Test PostgreSQL connection
kubectl run postgres-client --image=postgres:15 --rm -it --restart=Never --
psql -h your-db-host -U postgres -d source_db


## 🔄 CI/CD Integration

### GitHub Actions Example
name: Deploy to Staging
on:
push:
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
    
- name: Deploy to staging
  run: |
    ./scripts/deploy.sh staging


## 📈 Scaling

### Horizontal Scaling
Adjust replicas in environment values:
global:
redpanda:
replicas: 5
flink:
taskmanager:
replicas: 10


### Vertical Scaling
Increase resources:
global:
resources:
large:
requests:
memory: 4Gi
cpu: 2000m
limits:
memory: 8Gi
cpu: 4000m


## 🧹 Cleanup

Remove staging deployment
helm uninstall td-pipeline-staging -n td-pipeline-staging

Remove namespace
kubectl delete namespace td-pipeline-staging

Remove sealed secrets controller (if not needed)
helm uninstall sealed-secrets-controller -n kube-system

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test in dev environment
5. Submit a pull request

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.
This complete refactored codebase provides:

✅ Multi-environment support with proper values templating
✅ AWS S3 integration with Kafka Connect S3 sink connector
✅ Secure secrets management using Sealed Secrets
✅ External PostgreSQL configuration without containers
✅ Fully templated Helm charts with no hardcoded values
✅ Production-ready Flink jobs with proper checkpointing
✅ Comprehensive deployment scripts for easy automation
✅ Monitoring and troubleshooting guidelines


# repo structure:
```
td-pipeline/
├── charts/
│   ├── umbrella/                 # Main umbrella chart
│   │   ├── Chart.yaml
│   │   ├── values.yaml          # Default values
│   │   └── templates/
│   │       ├── _helpers.tpl
│   │       └── sealed-secrets.yaml
│   ├── redpanda/
│   │   ├── Chart.yaml
│   │   ├── values.yaml          # All templated values
│   │   └── templates/
│   ├── kafka-connect/
│   │   ├── Chart.yaml
│   │   ├── values.yaml          # AWS S3 sink ready
│   │   └── templates/
│   ├── flink/
│   │   ├── Chart.yaml
│   │   ├── values.yaml          # No hardcoded values
│   │   └── templates/
│   └── postgres/
│       ├── Chart.yaml
│       ├── values.yaml          # External DB config
│       └── templates/
├── environments/
│   ├── values-dev.yaml
│   ├── values-staging.yaml
│   └── values-prod.yaml
├── secrets/
│   ├── dev/
│   │   ├── postgres-credentials.yaml
│   │   └── aws-credentials.yaml
│   ├── staging/
│   │   ├── postgres-credentials.yaml
│   │   └── aws-credentials.yaml
│   └── prod/
│       ├── postgres-credentials.yaml
│       └── aws-credentials.yaml
├── flink-jobs/
│   ├── src/
│   │   └── main/
│   │       └── java/
│   │           └── CDCProcessor.java
│   ├── pom.xml
│   └── Dockerfile
├── scripts/
│   ├── deploy.sh
│   ├── setup-secrets.sh
│   └── build-flink-job.sh
└── README.md

```