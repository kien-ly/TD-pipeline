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
