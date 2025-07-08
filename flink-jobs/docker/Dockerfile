FROM flink:1.18.0

# Install Python and PyFlink
RUN apt-get update && apt-get install -y python3 python3-pip

# Install PyFlink
RUN pip3 install apache-flink==1.18.0

# Download required connectors
RUN wget -P /opt/flink/lib/ \
    https://repo.maven.apache.org/maven2/org/apache/flink/flink-sql-connector-kafka/1.18.0/flink-sql-connector-kafka-1.18.0.jar && \
    wget -P /opt/flink/lib/ \
    https://repo.maven.apache.org/maven2/org/apache/flink/flink-s3-fs-hadoop/1.18.0/flink-s3-fs-hadoop-1.18.0.jar && \
    wget -P /opt/flink/lib/ \
    https://repo.maven.apache.org/maven2/org/apache/flink/flink-sql-parquet/1.18.0/flink-sql-parquet-1.18.0.jar

# Copy job files
COPY flink-jobs/python/cdc_processor.py /opt/flink/jobs/

# Set working directory
WORKDIR /opt/flink

# Set entry point for job submission
ENTRYPOINT ["python3", "/opt/flink/jobs/cdc_processor.py"]
