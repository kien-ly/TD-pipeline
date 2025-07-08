#!/bin/bash
set -e

echo "🔗 Setting up Debezium PostgreSQL connector..."

# Wait for Kafka Connect to be ready
echo "Waiting for Kafka Connect to be ready..."
until curl -f http://localhost:8083/connectors; do
  echo "Waiting for Kafka Connect..."
  sleep 5
done

# Create Debezium PostgreSQL connector
cat << EOF | curl -X POST \
  -H "Content-Type: application/json" \
  --data @- \
  http://localhost:8083/connectors
{
  "name": "postgres-cdc-connector",
  "config": {
    "connector.class": "io.debezium.connector.postgresql.PostgresConnector",
    "tasks.max": "1",
    "database.hostname": "host.docker.internal",
    "database.port": "5432",
    "database.user": "postgres",
    "database.password": "postgres123",
    "database.dbname": "source_db",
    "database.server.name": "postgres",
    "table.include.list": "public.customers",
    "plugin.name": "pgoutput",
    "slot.name": "debezium_slot",
    "publication.autocreate.mode": "filtered"
  }
}
EOF

echo "✅ Debezium connector configured!"

# Check connector status
echo "📊 Connector status:"
curl -s http://localhost:8083/connectors/postgres-cdc-connector/status | jq
