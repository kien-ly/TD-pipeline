# TD-Pipeline: Data Engineering Pipeline with CDC

Complete data engineering pipeline with PostgreSQL CDC, Redpanda, Apache Flink, and MinIO S3 storage.

## 🏗️ Architecture

PostgreSQL (CDC) → Debezium → Redpanda → Apache Flink → MinIO (S3/Parquet)


## 🚀 Quick Start

### Prerequisites
- Docker Desktop with Kubernetes enabled
- Kind installed
- Helm 3.x installed
- kubectl configured

### 1. Setup Kind Cluster
```bash
chmod +x scripts/*.sh
./scripts/setup-kind.sh
```

### 2. Deploy Pipeline
```
./scripts/deploy.sh
```


### 3. Setup PostgreSQL Database
```sql
-- Create test database and table
CREATE DATABASE source_db;
\c source_db;

CREATE TABLE customers (
id SERIAL PRIMARY KEY,
name VARCHAR(255),
email VARCHAR(255),
created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Enable logical replication
ALTER SYSTEM SET wal_level = logical;
SELECT pg_reload_conf();
```

### 4. Configure CDC Connector
./scripts/setup-connectors.sh


### 5. Test the Pipeline

```sql
-- Insert test data
INSERT INTO customers (name, email) VALUES
('John Doe', 'john@example.com'),
('Jane Smith', 'jane@example.com');

-- Update data
UPDATE customers SET email = 'john.doe@example.com' WHERE id = 1;
```


## 🌐 Access URLs

- **Flink UI**: http://localhost:8081
- **Redpanda Console**: http://localhost:8082  
- **MinIO Console**: http://localhost:9001 (minioadmin/minioadmin123)
- **Kafka Connect**: http://localhost:8083

## 🔧 Port Forwarding Commands

Flink Web UI
kubectl port-forward -n td-pipeline service/flink-jobmanager 8081:8081

Redpanda Console
kubectl port-forward -n td-pipeline service/redpanda-console 8082:8080

MinIO Console
kubectl port-forward -n td-pipeline service/minio-console 9001:9001

Kafka Connect REST API
kubectl port-forward -n td-pipeline service/kafka-connect 8083:8083


## 🗄️ Data Verification

Check the MinIO bucket `cdc-data` for Parquet files containing the CDC data processed by Flink.

## 🧹 Cleanup
Remove deployment
helm uninstall td-pipeline -n td-pipeline

Delete Kind cluster
kind delete cluster --name td-pipeline


## 🐛 Troubleshooting

### Check Pod Status
kubectl get pods -n td-pipeline
kubectl logs -n td-pipeline <pod-name>


### Verify Connector Status
curl http://localhost:8083/connectors/postgres-cdc-connector/status


### Check Kafka Topics
kubectl exec -n td-pipeline redpanda-0 -- rpk topic list

text
undefined
🎯 Deployment Instructions
Create Kind cluster: ./scripts/setup-kind.sh

Deploy pipeline: ./scripts/deploy.sh

Setup connectors: ./scripts/setup-connectors.sh

Test end-to-end: Insert data into PostgreSQL and verify Parquet files in MinIO