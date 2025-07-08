#!/bin/bash
set -e

echo "🏗️ Building Flink job..."

# Check if Maven is installed
if ! command -v mvn &> /dev/null; then
    echo "❌ Maven is not installed. Please install Maven first."
    exit 1
fi

# Build the Flink job
cd flink-jobs
mvn clean package -DskipTests

# Check if JAR was created
if [[ -f "target/flink-cdc-processor-1.0.0.jar" ]]; then
    echo "✅ Flink job built successfully: target/flink-cdc-processor-1.0.0.jar"
else
    echo "❌ Flink job build failed"
    exit 1
fi

# Build Docker image with the job
echo "Building Docker image..."
docker build -t td-pipeline/flink-cdc-processor:1.0.0 .

echo "✅ Flink job and Docker image built successfully"
