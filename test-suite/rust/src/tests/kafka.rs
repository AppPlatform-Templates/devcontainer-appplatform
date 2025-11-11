use crate::utils::*;
use futures::executor::block_on;
use rdkafka::admin::{AdminClient, AdminOptions, NewTopic, TopicReplication};
use rdkafka::client::DefaultClientContext;
use rdkafka::config::ClientConfig;
use rdkafka::producer::{FutureProducer, FutureRecord};
use std::time::Duration;
use uuid::Uuid;

const SERVICE: &str = "Kafka";
const CLIENT_NAME: &str = "rust-rdkafka";

pub fn test_kafka() -> ServiceResult {
    let host = get_env("KAFKA_HOST", "kafka");
    let port = get_env_u16("KAFKA_PORT", 29092);
    let broker = format!("{}:{}", host, port);

    if let Some(gate) = verify_service_gate(SERVICE, CLIENT_NAME, "ENABLE_KAFKA", false, &host, port) {
        return gate;
    }

    run_check(SERVICE, CLIENT_NAME, || {
        let topic = format!("health-check-{}", Uuid::new_v4());

        // Create admin client
        let admin_client: AdminClient<DefaultClientContext> = ClientConfig::new()
            .set("bootstrap.servers", &broker)
            .create()?;

        // Create topic
        let new_topic = NewTopic::new(&topic, 1, TopicReplication::Fixed(1));
        let opts = AdminOptions::new().operation_timeout(Some(Duration::from_secs(5)));

        block_on(admin_client.create_topics(&[new_topic], &opts))
            .map_err(|e| format!("Failed to create topic: {:?}", e))?;

        // Give Kafka time to create the topic
        std::thread::sleep(Duration::from_millis(500));

        // Create producer
        let producer: FutureProducer = ClientConfig::new()
            .set("bootstrap.servers", &broker)
            .set("message.timeout.ms", "5000")
            .create()?;

        // Send message
        let record = FutureRecord::to(&topic)
            .key("test-key")
            .payload(CLIENT_NAME);

        let delivery_status = block_on(producer.send(record, Duration::from_secs(5)));

        match delivery_status {
            Ok(_) => Ok(format!("Produced message to topic {}", topic)),
            Err((e, _)) => Err(format!("Failed to produce message: {:?}", e).into()),
        }
    })
}
