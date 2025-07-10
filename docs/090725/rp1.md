<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" class="logo" width="120"/>

# Complete Technical Setup and Configuration Report: Data Engineering Project with Helm Umbrella Chart

## Executive Summary

This comprehensive report provides a complete technical setup and configuration guide for a data engineering project implementing Change Data Capture (CDC) using PostgreSQL, Debezium, Redpanda (Kafka-compatible), Kafka Connect, and Apache Flink on Kubernetes. The solution uses Helm umbrella charts for orchestration, implementing best practices for configuration management, secret handling, CI/CD, and observability.

## Architecture Overview

The project implements the following data flow:

```
PostgreSQL → Debezium CDC Source Connector → Redpanda Broker (Kafka API) → [Raw Logs to S3] + [Apache Flink ETL] → S3 Data Warehouse
```

All components are deployed on Kubernetes using Helm charts organized in an umbrella chart pattern for centralized management and configuration.

## 1. Helm Umbrella Chart Structure

### 1.1 Chart Organization

The umbrella chart pattern allows for centralized management of multiple subcharts as dependencies[1][2]. The recommended structure is:

```
data-engineering-platform/
├── Chart.yaml                 # Main umbrella chart metadata
├── values.yaml                # Global configuration values
├── values-dev.yaml            # Development environment overrides
├── values-staging.yaml        # Staging environment overrides
├── values-prod.yaml           # Production environment overrides
├── charts/                    # Directory for subchart dependencies
│   ├── debezium/
│   ├── redpanda/
│   ├── kafka-connect/
│   ├── flink/                 # Optional
│   └── monitoring/
├── templates/                 # Global templates (if any)
│   └── _helpers.tpl
└── secrets/                   # Secret management templates
    ├── external-secrets.yaml
    └── ...
```


### 1.2 Chart.yaml Configuration

```yaml
apiVersion: v2
name: data-engineering-platform
description: Umbrella chart for data engineering platform with CDC pipeline
type: application
version: 1.0.0
appVersion: "1.0"

dependencies:
  - name: postgresql
    version: "15.2.5"
    repository: "https://charts.bitnami.com/bitnami"
    condition: postgresql.enabled
  
  - name: redpanda
    version: "5.8.46"
    repository: "https://charts.redpanda.com"
    condition: redpanda.enabled
  
  - name: kafka-connect
    version: "0.1.2"
    repository: "https://charts.redpanda.com"
    condition: kafka-connect.enabled
  
  - name: flink-kubernetes-operator
    version: "1.10.0"
    repository: "https://downloads.apache.org/flink/flink-kubernetes-operator-1.10.0/"
    condition: flink.enabled
  
  - name: prometheus
    version: "25.27.0"
    repository: "https://prometheus-community.github.io/helm-charts"
    condition: monitoring.prometheus.enabled
  
  - name: grafana
    version: "8.5.2"
    repository: "https://grafana.github.io/helm-charts"
    condition: monitoring.grafana.enabled
```


### 1.3 Global Values Configuration

The main `values.yaml` provides global defaults that can be overridden by environment-specific files[3][4]:

```yaml
global:
  environment: development
  domain: platform.local
  storageClass: standard
  
  # Global resource limits
  resources:
    limits:
      cpu: 1000m
      memory: 1Gi
    requests:
      cpu: 500m
      memory: 512Mi

  # Global image pull secrets
  imagePullSecrets:
    - name: registry-secret

# Component configurations
postgresql:
  enabled: true
  auth:
    existingSecret: "postgres-credentials"
  primary:
    persistence:
      storageClass: "{{ .Values.global.storageClass }}"
      size: 20Gi

redpanda:
  enabled: true
  storage:
    persistentVolume:
      storageClass: "{{ .Values.global.storageClass }}"
      size: 50Gi

kafka-connect:
  enabled: true
  replicaCount: 2
  
flink:
  enabled: true
  flinkConfiguration:
    metrics.reporter.prometheus.class: org.apache.flink.metrics.prometheus.PrometheusReporter

monitoring:
  prometheus:
    enabled: true
  grafana:
    enabled: true
```


## 2. Configuration Management Best Practices

### 2.1 Helm Templating Techniques

Effective use of Helm templating functions ensures maintainable and reusable configurations[5][6]:

```yaml
# Using conditional logic for environment-specific resources
{{- if eq .Values.global.environment "production" }}
apiVersion: v1
kind: Service
metadata:
  name: {{ include "platform.fullname" . }}-lb
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
spec:
  type: LoadBalancer
{{- else }}
apiVersion: v1
kind: Service
metadata:
  name: {{ include "platform.fullname" . }}-nodeport
spec:
  type: NodePort
{{- end }}

# Template helpers for reusability
{{- define "platform.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- printf "%s-%s" $name .Values.global.environment | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

# Using template functions for data transformation
config:
  kafkaBootstrapServers: {{ .Values.redpanda.fullnameOverride | default "redpanda" }}.{{ .Release.Namespace }}.svc.cluster.local:9092
  s3Endpoint: {{ .Values.s3.endpoint | quote }}
  region: {{ .Values.global.aws.region | default "us-west-2" | quote }}
```


### 2.2 Values File Structure

Organize values hierarchically for maintainability[7][4]:

```yaml
# values.yaml - Base configuration
kafka:
  topics:
    cdc-events:
      partitions: 12
      replicationFactor: 3
    raw-logs:
      partitions: 6
      replicationFactor: 3

s3:
  buckets:
    rawData: "raw-cdc-logs"
    transformedData: "transformed-data-warehouse"
    
debezium:
  connectors:
    postgres:
      name: "postgres-source-connector"
      config:
        database.hostname: "{{ include \"postgresql.primary.fullname\" .Subcharts.postgresql }}"
        database.port: 5432
        database.user: "debezium"
        database.dbname: "inventory"
        database.server.name: "dbserver1"
        table.include.list: "inventory.customers,inventory.orders"
```


### 2.3 Sharing Values Between Charts

Use global values and chart interdependencies[1][8]:

```yaml
# In umbrella chart values.yaml
global:
  kafka:
    bootstrapServers: "redpanda.{{ .Release.Namespace }}.svc.cluster.local:9092"
  
# Subcharts can access global values
debezium:
  connect:
    config:
      bootstrap.servers: "{{ .Values.global.kafka.bootstrapServers }}"

flink:
  flinkConfiguration:
    kubernetes.flink.conf.dir: /opt/flink/conf
    pipeline.jars: "file:///opt/flink/lib/flink-connector-kafka.jar"
    execution.checkpointing.interval: 60000
```


## 3. Environment-Specific Variable Handling

### 3.1 Environment Values Files

Create separate values files for each environment[9][10]:

```yaml
# values-dev.yaml
global:
  environment: development
  domain: dev.platform.local

postgresql:
  primary:
    persistence:
      size: 10Gi
  auth:
    database: "inventory_dev"

redpanda:
  storage:
    persistentVolume:
      size: 20Gi
  config:
    cluster:
      auto_create_topics_enabled: true

# values-prod.yaml
global:
  environment: production
  domain: platform.company.com

postgresql:
  primary:
    persistence:
      size: 100Gi
  auth:
    database: "inventory_prod"

redpanda:
  storage:
    persistentVolume:
      size: 200Gi
  config:
    cluster:
      auto_create_topics_enabled: false
```


### 3.2 Professional Configuration Management

#### Using Helmfile for Multi-Environment Management

Helmfile provides declarative management across environments[9][11]:

```yaml
# helmfile.yaml
environments:
  development:
    values:
      - values-dev.yaml
  staging:
    values:
      - values-staging.yaml
  production:
    values:
      - values-prod.yaml

releases:
  - name: data-engineering-platform
    chart: ./data-engineering-platform
    namespace: data-platform-{{ .Environment.Name }}
    values:
      - values.yaml
      - values-{{ .Environment.Name }}.yaml
    hooks:
      - events: ["prepare"]
        command: "./scripts/create-secrets.sh"
        args: ["{{ .Environment.Name }}"]
```


#### Using Kustomize for Configuration Overlays

Kustomize provides an alternative approach for environment-specific customizations[12][13]:

```yaml
# base/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - namespace.yaml
  - ../helm-output

# overlays/production/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: data-platform-prod

resources:
  - ../../base

patchesStrategicMerge:
  - replica-count.yaml
  - resource-limits.yaml
```


### 3.3 Secret Management Best Practices

#### External Secrets Operator

External Secrets Operator provides secure integration with external secret stores[14][15]:

```yaml
# external-secrets.yaml
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: aws-secrets-manager
spec:
  provider:
    aws:
      service: SecretsManager
      region: us-west-2
      auth:
        jwt:
          serviceAccountRef:
            name: external-secrets-sa

---
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: database-credentials
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: aws-secrets-manager
    kind: SecretStore
  target:
    name: postgres-credentials
    creationPolicy: Owner
  data:
    - secretKey: username
      remoteRef:
        key: /platform/database/credentials
        property: username
    - secretKey: password
      remoteRef:
        key: /platform/database/credentials
        property: password
```


#### Sealed Secrets

For GitOps workflows, use Sealed Secrets to encrypt secrets in version control[16][17]:

```yaml
# Install Sealed Secrets Controller
helm install sealed-secrets sealed-secrets/sealed-secrets \
  --namespace sealed-secrets \
  --create-namespace

# Create sealed secret
echo -n 'supersecret' | kubectl create secret generic database-password \
  --dry-run=client --from-file=password=/dev/stdin -o yaml | \
  kubeseal -o yaml > database-password-sealed.yaml
```


#### HashiCorp Vault Integration

Vault provides comprehensive secret management for Kubernetes[18][19]:

```yaml
# Install Vault using Helm
helm install vault hashicorp/vault \
  --namespace vault \
  --create-namespace \
  --set server.ha.enabled=true \
  --set server.ha.raft.enabled=true

# Vault Agent Injector configuration
apiVersion: v1
kind: Pod
metadata:
  annotations:
    vault.hashicorp.com/agent-inject: "true"
    vault.hashicorp.com/agent-inject-secret-database: "database/creds/readonly"
    vault.hashicorp.com/agent-inject-template-database: |
      {{- with secret "database/creds/readonly" -}}
      username={{ .Data.username }}
      password={{ .Data.password }}
      {{- end }}
spec:
  serviceAccountName: vault-auth
  containers:
    - name: app
      image: my-app:latest
```


## 4. CI/CD and Deployment Flow

### 4.1 Helm Deployment Commands

Standard deployment commands for each environment[20][21]:

```bash
# Development deployment
helm upgrade --install data-platform ./data-engineering-platform \
  --namespace data-platform-dev \
  --create-namespace \
  --values values.yaml \
  --values values-dev.yaml \
  --timeout 600s

# Staging deployment with dependency update
helm dependency update ./data-engineering-platform
helm upgrade --install data-platform ./data-engineering-platform \
  --namespace data-platform-staging \
  --create-namespace \
  --values values.yaml \
  --values values-staging.yaml \
  --wait \
  --timeout 900s

# Production deployment with atomic rollback
helm upgrade --install data-platform ./data-engineering-platform \
  --namespace data-platform-prod \
  --create-namespace \
  --values values.yaml \
  --values values-prod.yaml \
  --atomic \
  --timeout 1200s
```


### 4.2 Rollback and Upgrade Strategies

Implement robust rollback capabilities[21][20]:

```bash
# Check release history
helm history data-platform -n data-platform-prod

# Rollback to previous version
helm rollback data-platform -n data-platform-prod

# Rollback to specific revision
helm rollback data-platform 5 -n data-platform-prod

# Dry run upgrade to test changes
helm upgrade data-platform ./data-engineering-platform \
  --namespace data-platform-prod \
  --values values.yaml \
  --values values-prod.yaml \
  --dry-run
```


### 4.3 GitOps Flow with ArgoCD

ArgoCD provides declarative GitOps deployment[22][23]:

```yaml
# argocd-application.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: data-engineering-platform
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/company/data-platform-helm
    targetRevision: main
    path: data-engineering-platform
    helm:
      valueFiles:
        - values.yaml
        - values-prod.yaml
  destination:
    server: https://kubernetes.default.svc
    namespace: data-platform-prod
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
      - ServerSideApply=true
```


### 4.4 GitOps Flow with FluxCD

FluxCD offers an alternative GitOps approach[24][25]:

```yaml
# flux-helmrelease.yaml
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: data-engineering-platform
  namespace: data-platform-prod
spec:
  interval: 5m
  chart:
    spec:
      chart: ./data-engineering-platform
      sourceRef:
        kind: GitRepository
        name: platform-repo
        namespace: flux-system
  values:
    global:
      environment: production
  valuesFrom:
    - kind: Secret
      name: platform-secrets
      valuesKey: values.yaml
```


### 4.5 GitHub Actions CI/CD Integration

Automate deployments using GitHub Actions[26][27]:

```yaml
# .github/workflows/deploy.yaml
name: Deploy Data Platform
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Helm
        uses: azure/setup-helm@v3
        with:
          version: '3.12.0'
      
      - name: Configure kubectl
        uses: azure/k8s-set-context@v1
        with:
          method: kubeconfig
          kubeconfig: ${{ secrets.KUBE_CONFIG }}
      
      - name: Lint Helm Chart
        run: |
          helm dependency update ./data-engineering-platform
          helm lint ./data-engineering-platform
      
      - name: Deploy to Staging
        if: github.event_name == 'pull_request'
        run: |
          helm upgrade --install data-platform ./data-engineering-platform \
            --namespace data-platform-staging \
            --create-namespace \
            --values values.yaml \
            --values values-staging.yaml \
            --atomic
      
      - name: Deploy to Production
        if: github.ref == 'refs/heads/main'
        run: |
          helm upgrade --install data-platform ./data-engineering-platform \
            --namespace data-platform-prod \
            --create-namespace \
            --values values.yaml \
            --values values-prod.yaml \
            --atomic
```


## 5. Observability and Debugging

### 5.1 Prometheus Integration

Configure Prometheus for comprehensive monitoring[28][29]:

```yaml
# monitoring/prometheus-values.yaml
prometheus:
  prometheusSpec:
    serviceMonitorSelectorNilUsesHelmValues: false
    ruleNamespaceSelector: {}
    ruleSelector: {}
    serviceMonitorNamespaceSelector: {}
    serviceMonitorSelector: {}
    
    additionalScrapeConfigs:
      - job_name: 'redpanda'
        static_configs:
          - targets: ['redpanda:9644']
        metrics_path: /metrics
        scrape_interval: 30s
      
      - job_name: 'flink-metrics'
        static_configs:
          - targets: ['flink-jobmanager:9249']
        metrics_path: /
        scrape_interval: 30s

# ServiceMonitor for Kafka Connect
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: kafka-connect-metrics
spec:
  selector:
    matchLabels:
      app: kafka-connect
  endpoints:
    - port: metrics
      interval: 30s
      path: /metrics
```


### 5.2 Grafana Dashboard Configuration

Deploy Grafana with pre-configured dashboards[30][31]:

```yaml
# monitoring/grafana-values.yaml
grafana:
  adminPassword: "admin123"
  
  dashboardProviders:
    dashboardproviders.yaml:
      apiVersion: 1
      providers:
        - name: 'default'
          orgId: 1
          folder: ''
          type: file
          disableDeletion: false
          editable: true
          options:
            path: /var/lib/grafana/dashboards/default
  
  dashboards:
    default:
      flink-metrics:
        gnetId: 14840
        revision: 1
        datasource: Prometheus
      
      kafka-overview:
        gnetId: 7589
        revision: 1
        datasource: Prometheus

  datasources:
    datasources.yaml:
      apiVersion: 1
      datasources:
        - name: Prometheus
          type: prometheus
          url: http://prometheus-server
          access: proxy
          isDefault: true
```


### 5.3 ELK Stack for Logging

Deploy centralized logging with ELK stack[32][33]:

```yaml
# logging/elk-values.yaml
elasticsearch:
  replicas: 3
  persistence:
    enabled: true
    size: 100Gi
  resources:
    requests:
      cpu: 1000m
      memory: 2Gi
    limits:
      cpu: 2000m
      memory: 4Gi

filebeat:
  daemonset:
    enabled: true
  filebeatConfig:
    filebeat.yml: |
      filebeat.inputs:
      - type: container
        paths:
          - /var/log/containers/*data-platform*.log
        processors:
        - add_kubernetes_metadata:
            host: ${NODE_NAME}
            matchers:
            - logs_path:
                logs_path: "/var/log/containers/"
      
      output.elasticsearch:
        hosts: ["elasticsearch-master:9200"]
        index: "filebeat-data-platform-%{+yyyy.MM.dd}"

kibana:
  elasticsearchHosts: "http://elasticsearch-master:9200"
  resources:
    requests:
      cpu: 500m
      memory: 1Gi
```


## 6. Optional Enhancements

### 6.1 Apache Iceberg Integration with Flink

Enable lakehouse capabilities with Apache Iceberg[34][35]:

```yaml
# flink/iceberg-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: flink-iceberg-config
data:
  flink-conf.yaml: |
    execution.checkpointing.interval: 60000
    state.backend: rocksdb
    state.checkpoints.dir: s3://checkpoints-bucket/
    
    # Iceberg catalog configuration
    table.exec.iceberg.infer-source-parallelism: true
    table.exec.iceberg.expose-split-assignment: true

# Flink SQL job for Iceberg integration
apiVersion: flink.apache.org/v1beta1
kind: FlinkDeployment
metadata:
  name: iceberg-etl-job
spec:
  image: apache/flink:1.18.0
  flinkVersion: v1_18
  flinkConfiguration:
    taskmanager.numberOfTaskSlots: "4"
    high-availability: org.apache.flink.kubernetes.highavailability.KubernetesHaServicesFactory
    high-availability.storageDir: s3://flink-ha/
  
  job:
    jarURI: local:///opt/flink/lib/flink-sql-connector-iceberg.jar
    entryClass: org.apache.flink.table.planner.delegation.BatchPlanner
    args: []
    
  taskManager:
    resource:
      memory: 2048Mi
      cpu: 1
```


### 6.2 Schema Registry Setup

Configure Schema Registry for data governance[36][37]:

```yaml
# schema-registry/values.yaml
schemaRegistry:
  replicaCount: 2
  
  configurationOverrides:
    kafkastore.bootstrap.servers: "redpanda:9092"
    kafkastore.topic: "_schemas"
    schema.compatibility.level: "backward"
    
  resources:
    requests:
      cpu: 500m
      memory: 1Gi
    limits:
      cpu: 1000m
      memory: 2Gi

# Example connector configuration with Schema Registry
debezium:
  connectors:
    postgres-avro:
      config:
        name: "postgres-avro-connector"
        connector.class: "io.debezium.connector.postgresql.PostgresConnector"
        value.converter: "io.confluent.connect.avro.AvroConverter"
        value.converter.schema.registry.url: "http://schema-registry:8081"
        key.converter: "io.confluent.connect.avro.AvroConverter"
        key.converter.schema.registry.url: "http://schema-registry:8081"
```


### 6.3 Flink Metrics Export Configuration

Configure comprehensive Flink metrics export[38][39]:

```yaml
# flink-metrics-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: flink-metrics-config
data:
  flink-conf.yaml: |
    # Prometheus metrics reporter
    metrics.reporter.prometheus.class: org.apache.flink.metrics.prometheus.PrometheusReporter
    metrics.reporter.prometheus.port: 9249
    metrics.reporter.prometheus.interval: 30 SECONDS
    
    # Kafka metrics reporter
    metrics.reporter.kafka.class: org.apache.flink.metrics.kafka.KafkaMetricsReporter
    metrics.reporter.kafka.topic: flink-metrics
    metrics.reporter.kafka.bootstrap.servers: redpanda:9092
    metrics.reporter.kafka.interval: 60 SECONDS
    
    # JMX metrics
    metrics.reporter.jmx.class: org.apache.flink.metrics.jmx.JMXReporter
    metrics.reporter.jmx.port: 8789
```


## 7. References and Deep Research Citations

This report is based on extensive research from authoritative sources:

### Helm and Kubernetes Configuration Management

- **Helm Official Documentation**: Comprehensive guide to Helm dependency management and chart structure[1][2]
- **Helm Template Best Practices**: Official CNCF guidelines for template structure and formatting[3][8]
- **Advanced Helm Templating**: Community best practices for template functions and pipelines[5][6]


### Secret Management

- **External Secrets Operator**: Official GitHub repository and integration guides[14][15]
- **Sealed Secrets**: Bitnami's solution for GitOps-friendly secret management[16][17]
- **HashiCorp Vault**: Official documentation for Kubernetes integration[18][19]


### GitOps and CI/CD

- **ArgoCD with Helm**: Official documentation for GitOps deployment patterns[22][23]
- **FluxCD Integration**: Cloud Native Computing Foundation documentation[24][25]
- **GitHub Actions**: Official guides for Kubernetes CI/CD automation[26][27]


### Observability

- **Prometheus Helm Charts**: Community-maintained charts for monitoring[28][29]
- **Grafana Kubernetes Monitoring**: Official Grafana Labs documentation[30][31]
- **ELK Stack on Kubernetes**: Comprehensive logging solution guides[32][33]


### Environment Management

- **Helmfile**: Official documentation for multi-environment management[9][11]
- **Kustomize**: Kubernetes-native configuration management[12][13]


### Component-Specific Configuration

- **Redpanda Helm Charts**: Official Redpanda documentation for Kubernetes deployment[40][41]
- **Debezium on Kubernetes**: Apache Debezium project documentation[42][43]
- **Apache Flink Operator**: Official Kubernetes operator documentation[44][39]


### Advanced Integrations

- **Apache Iceberg**: Documentation for lakehouse format integration[34][35]
- **Schema Registry**: Confluent and Apache documentation[36][37]
- **Flink Metrics**: Apache Flink monitoring and metrics configuration[38][39]

This comprehensive setup provides a production-ready, scalable, and maintainable data engineering platform using modern cloud-native technologies and best practices. The modular architecture ensures flexibility while maintaining operational excellence through proper observability, secret management, and automated deployment processes.