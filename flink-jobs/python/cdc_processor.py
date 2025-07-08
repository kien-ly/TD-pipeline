#!/usr/bin/env python3
"""
PyFlink CDC Processor
Reads from Redpanda (Kafka) and writes to MinIO (S3) in Parquet format
"""

from pyflink.datastream import StreamExecutionEnvironment, RuntimeExecutionMode
from pyflink.table import StreamTableEnvironment, EnvironmentSettings
from pyflink.common import Configuration
import logging
import sys

def create_cdc_processor():
    """Create and configure Flink CDC processor"""
    
    # Set up environment
    env = StreamExecutionEnvironment.get_execution_environment()
    env.set_runtime_mode(RuntimeExecutionMode.STREAMING)
    env.set_parallelism(2)
    
    # Configure checkpointing
    env.enable_checkpointing(30000)  # 30 seconds
    
    # Add required JARs
    env_settings = EnvironmentSettings.new_instance().in_streaming_mode().build()
    table_env = StreamTableEnvironment.create(env, environment_settings=env_settings)
    
    # Configure JAR dependencies
    configuration = Configuration()
    configuration.set_string("pipeline.jars", 
        "file:///opt/flink/lib/flink-sql-connector-kafka-1.18.0.jar;"
        "file:///opt/flink/lib/flink-s3-fs-hadoop-1.18.0.jar;"
        "file:///opt/flink/lib/flink-sql-parquet-1.18.0.jar"
    )
    
    table_env.get_config().add_configuration(configuration)
    
    return table_env

def setup_source_table(table_env):
    """Setup Kafka source table for CDC data"""
    
    source_ddl = """
    CREATE TABLE postgres_cdc_source (
        id BIGINT,
        name STRING,
        email STRING,
        created_at TIMESTAMP(3),
        updated_at TIMESTAMP(3),
        operation STRING,
        table_name STRING,
        database_name STRING,
        event_time TIMESTAMP(3) METADATA FROM 'timestamp',
        WATERMARK FOR event_time AS event_time - INTERVAL '5' SECOND
    ) WITH (
        'connector' = 'kafka',
        'topic' = 'postgres.public.customers',
        'properties.bootstrap.servers' = 'redpanda:9092',
        'properties.group.id' = 'flink-cdc-processor',
        'scan.startup.mode' = 'earliest-offset',
        'format' = 'debezium-json'
    )
    """
    
    table_env.execute_sql(source_ddl)
    logging.info("Created Kafka source table")

def setup_sink_table(table_env):
    """Setup S3 sink table for Parquet output"""
    
    sink_ddl = """
    CREATE TABLE s3_parquet_sink (
        id BIGINT,
        name STRING,
        email STRING,
        created_at TIMESTAMP(3),
        updated_at TIMESTAMP(3),
        operation STRING,
        table_name STRING,
        database_name STRING,
        event_time TIMESTAMP(3),
        processing_date STRING,
        processing_hour STRING
    ) PARTITIONED BY (processing_date, processing_hour) WITH (
        'connector' = 'filesystem',
        'path' = 's3://cdc-data/postgres-cdc',
        'format' = 'parquet',
        'sink.partition-commit.delay' = '1 min',
        'sink.partition-commit.policy.kind' = 'success-file',
        'sink.rolling-policy.file-size' = '128MB',
        'sink.rolling-policy.rollover-interval' = '1 min'
    )
    """
    
    table_env.execute_sql(sink_ddl)
    logging.info("Created S3 Parquet sink table")

def process_cdc_data(table_env):
    """Process CDC data and write to S3"""
    
    processing_query = """
    INSERT INTO s3_parquet_sink
    SELECT 
        id,
        name,
        email,
        created_at,
        updated_at,
        operation,
        table_name,
        database_name,
        event_time,
        DATE_FORMAT(event_time, 'yyyy-MM-dd') as processing_date,
        DATE_FORMAT(event_time, 'HH') as processing_hour
    FROM postgres_cdc_source
    WHERE operation IN ('INSERT', 'UPDATE', 'DELETE')
    """
    
    return table_env.execute_sql(processing_query)

def main():
    """Main execution function"""
    
    logging.basicConfig(level=logging.INFO)
    logging.info("Starting CDC Processor job")
    
    try:
        # Initialize Flink environment
        table_env = create_cdc_processor()
        
        # Setup source and sink tables
        setup_source_table(table_env)
        setup_sink_table(table_env)
        
        # Process CDC data
        result = process_cdc_data(table_env)
        
        logging.info("CDC Processor job started successfully")
        
        # Wait for job completion
        result.wait()
        
    except Exception as e:
        logging.error(f"CDC Processor job failed: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    main()
