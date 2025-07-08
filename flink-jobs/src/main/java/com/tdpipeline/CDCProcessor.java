// flink-jobs/src/main/java/com/tdpipeline/CDCProcessor.java
package com.tdpipeline;

import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;
import org.apache.flink.streaming.api.datastream.DataStream;
import org.apache.flink.streaming.connectors.kafka.FlinkKafkaConsumer;
import org.apache.flink.streaming.connectors.kafka.FlinkKafkaProducer;
import org.apache.flink.api.common.serialization.SimpleStringSchema;
import org.apache.flink.streaming.api.functions.ProcessFunction;
import org.apache.flink.util.Collector;
import org.apache.flink.shaded.jackson2.com.fasterxml.jackson.databind.ObjectMapper;
import org.apache.flink.shaded.jackson2.com.fasterxml.jackson.databind.JsonNode;

import java.util.Properties;

public class CDCProcessor {
    
    public static void main(String[] args) throws Exception {
        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
        
        // Configure checkpointing
        env.enableCheckpointing(60000); // 1 minute
        env.getCheckpointConfig().setCheckpointStorage("s3://td-pipeline-checkpoints/");
        
        // Kafka consumer properties
        Properties consumerProps = new Properties();
        consumerProps.setProperty("bootstrap.servers", System.getenv("KAFKA_BOOTSTRAP_SERVERS"));
        consumerProps.setProperty("group.id", "flink-cdc-processor");
        
        // Create Kafka consumer
        FlinkKafkaConsumer<String> consumer = new FlinkKafkaConsumer<>(
            "td-pipeline.*", // Topic pattern
            new SimpleStringSchema(),
            consumerProps
        );
        
        // Process CDC events
        DataStream<String> cdcStream = env.addSource(consumer);
        
        DataStream<String> processedStream = cdcStream
            .process(new CDCTransformer())
            .name("CDC Transformer");
        
        // Configure S3 sink
        processedStream.addSink(new S3ParquetSink())
            .name("S3 Parquet Sink");
        
        env.execute("CDC Processor Job");
    }
    
    public static class CDCTransformer extends ProcessFunction<String, String> {
        private ObjectMapper objectMapper = new ObjectMapper();
        
        @Override
        public void processElement(String value, Context ctx, Collector<String> out) throws Exception {
            JsonNode event = objectMapper.readTree(value);
            
            // Extract change event details
            JsonNode payload = event.get("payload");
            if (payload != null) {
                String operation = payload.get("op").asText();
                JsonNode before = payload.get("before");
                JsonNode after = payload.get("after");
                
                // Transform and enrich the data
                JsonNode transformedEvent = transformEvent(operation, before, after);
                
                out.collect(transformedEvent.toString());
            }
        }
        
        private JsonNode transformEvent(String operation, JsonNode before, JsonNode after) {
            // Implement your transformation logic here
            // This is where you can add business logic, data enrichment, etc.
            return after != null ? after : before;
        }
    }
}
