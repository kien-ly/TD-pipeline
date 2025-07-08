# Streaming Platform Scripts

This directory contains utility scripts for managing the streaming platform.

---

## Available Scripts

### 1. `enable-feature.sh`
Enables specific features in the streaming platform.

**Usage:**

```bash
./enable-feature.sh <feature-name> [environment]
```

**Available features:**
- `analytics` — Enable analytics connector
- `ml-pipeline` — Enable machine learning pipeline
- `data-catalog` — Enable data catalog service
- `superset` — Enable Apache Superset integration

**Examples:**

```bash
./enable-feature.sh analytics
./enable-feature.sh ml-pipeline production
```

---

### 2. `disable-feature.sh`
Disables specific features in the streaming platform.

**Usage:**

```bash
./disable-feature.sh <feature-name> [environment] [--force]
```

**Options:**
- `--force` — Force disable without confirmation

**Examples:**

```bash
./disable-feature.sh analytics
./disable-feature.sh ml-pipeline production --force
```

---

### 3. `setup-external-services.sh`
Sets up external service integrations.

**Usage:**

```bash
./setup-external-services.sh <service-type> [options]
```

**Available service types:**
- `superset` — Setup Apache Superset
- `aws` — Setup AWS integration
- `gcp` — Setup Google Cloud Platform integration
- `azure` — Setup Azure integration
- `external-api` — Setup external API connections
- `all` — Setup all external services

**Options:**
- `--env <env>` — Environment (dev/staging/prod)
- `--dry-run` — Show what would be done without executing
- `--force` — Force setup even if service exists

**Examples:**

```bash
./setup-external-services.sh superset --env dev
./setup-external-services.sh aws --dry-run
./setup-external-services.sh all --env production
```

---

### 4. `configure-integrations.sh`
Configures various integrations and connections.

**Usage:**

```bash
./configure-integrations.sh <integration-type> [options]
```

**Available integration types:**
- `database` — Configure database connections
- `messaging` — Configure messaging systems (Kafka, RabbitMQ)
- `monitoring` — Configure monitoring and alerting
- `storage` — Configure storage systems (S3, GCS, Azure)
- `api-gateway` — Configure API gateway settings
- `security` — Configure security and authentication
- `all` — Configure all integrations

**Options:**
- `--env <env>` — Environment (dev/staging/prod)
- `--dry-run` — Show what would be done without executing
- `--backup` — Create backup before configuration
- `--validate` — Validate configuration after setup

**Examples:**

```bash
./configure-integrations.sh database --env dev --validate
./configure-integrations.sh messaging --dry-run
./configure-integrations.sh all --env production --backup
```

---

### 5. `health-check.sh`
Performs comprehensive health checks on all platform components.

**Usage:**

```bash
./health-check.sh [options]
```

**Options:**
- `--env <env>` — Environment to check (dev/staging/prod)
- `--component <comp>` — Check specific component only
- `--detailed` — Show detailed health information
- `--metrics` — Show performance metrics
- `--report` — Generate health report
- `--continuous` — Run continuous monitoring
- `--timeout <sec>` — Timeout for health checks (default: 30)

**Available components:**
- `core` — Core platform services (RedPanda, Flink, Debezium)
- `optional` — Optional services (Analytics, ML, Data Catalog)
- `integrations` — External integrations (Superset, APIs, Cloud)
- `storage` — Storage systems
- `networking` — Network connectivity
- `all` — All components (default)

**Examples:**

```bash
./health-check.sh --env dev --detailed
./health-check.sh --component core --metrics
./health-check.sh --env production --report
./health-check.sh --continuous
```

---

## Common Workflows

### Initial Platform Setup

```bash
# 1. Setup external services
./setup-external-services.sh all --env dev

# 2. Configure integrations
./configure-integrations.sh all --env dev --validate

# 3. Enable required features
./enable-feature.sh analytics dev
./enable-feature.sh ml-pipeline dev

# 4. Verify health
./health-check.sh --env dev --detailed
```

### Production Deployment

```bash
# 1. Setup production environment
./setup-external-services.sh all --env production

# 2. Configure with backup
./configure-integrations.sh all --env production --backup --validate

# 3. Enable features
./enable-feature.sh analytics production
./enable-feature.sh ml-pipeline production

# 4. Continuous monitoring
./health-check.sh --env production --continuous
```

### Troubleshooting

```bash
# Check specific component health
./health-check.sh --component core --detailed

# Generate health report
./health-check.sh --env production --report

# Dry run configuration changes
./configure-integrations.sh database --env production --dry-run
```

---

## Script Features

All scripts include:
- **Colored output** for better readability
- **Comprehensive error handling** with meaningful error messages
- **Help documentation** accessible via `--help` or when no arguments provided
- **Environment validation** to prevent misconfigurations
- **Dry-run mode** for safe testing
- **Detailed logging** for troubleshooting

---

## Dependencies

These scripts are designed to work with:
- Kubernetes cluster with Helm installed
- Streaming platform components (RedPanda, Flink, Debezium)
- External services (Apache Superset, Cloud providers)
- Bash shell environment

---

## Notes

- All scripts are designed as **dummy implementations** for demonstration purposes
- In a real environment, these scripts would make actual API calls and configuration changes
- Scripts include simulated delays and random failures to demonstrate error handling
- Health checks simulate real service endpoints and response times
- Always test scripts in a development environment before using in production 