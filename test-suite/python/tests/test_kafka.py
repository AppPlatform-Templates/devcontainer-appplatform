from __future__ import annotations

import os
import time
import uuid

from kafka import KafkaConsumer, KafkaProducer
from kafka.admin import KafkaAdminClient, NewTopic
from kafka.errors import KafkaTimeoutError, NodeNotReadyError, TopicAlreadyExistsError

from utils import run_check, verify_service_gate

SERVICE = "Kafka"
CLIENT = "python-kafka-python"

LOOPBACK_HOSTS = {"localhost", "127.0.0.1"}
KAFKA_INTERNAL_ENDPOINT = "kafka:29092"


def _parse_host_port(entry: str) -> tuple[str, int]:
    host, _, port = entry.partition(":")
    return host or "kafka", int(port or "29092")


def _prioritize_brokers(raw_brokers: list[str]) -> list[str]:
    normalized: list[str] = []
    seen: set[str] = set()
    for broker in raw_brokers:
        if not broker:
            continue
        host, port = _parse_host_port(broker.strip())
        entry = f"{host}:{port}"
        if entry not in seen:
            normalized.append(entry)
            seen.add(entry)

    prioritized: list[str] = []
    has_kafka_host = any(_parse_host_port(entry)[0] == "kafka" for entry in normalized)
    if has_kafka_host:
        prioritized.append(KAFKA_INTERNAL_ENDPOINT)

    # Prefer non-loopback entries next, then fall back to loopback/localhost endpoints.
    for entry in normalized:
        host, _ = _parse_host_port(entry)
        if entry not in prioritized and host not in LOOPBACK_HOSTS:
            prioritized.append(entry)
    for entry in normalized:
        if entry not in prioritized:
            prioritized.append(entry)

    return prioritized or [KAFKA_INTERNAL_ENDPOINT]


def _retry_node_ready(func, attempts: int = 5, delay: float = 1.0):
    last_error: Exception | None = None
    for attempt in range(attempts):
        try:
            return func()
        except (NodeNotReadyError, KafkaTimeoutError) as exc:
            last_error = exc
            if attempt == attempts - 1:
                raise
            time.sleep(delay)
    if last_error:
        raise last_error


def run_test():
    brokers_raw = os.getenv("KAFKA_BROKERS", "kafka:29092")
    brokers = _prioritize_brokers(brokers_raw.split(","))
    if not brokers:
        brokers = ["kafka:29092"]
    host, port = _parse_host_port(brokers[0])
    topic = os.getenv("KAFKA_HEALTH_TOPIC")
    if not topic:
        topic = f"health-check-{uuid.uuid4()}"

    gate = verify_service_gate(SERVICE, CLIENT, "ENABLE_KAFKA", False, host, port)
    if gate:
        return gate

    def _ensure_topic():
        admin = KafkaAdminClient(
            bootstrap_servers=brokers,
            client_id="python-health-check",
        )
        try:
            admin.create_topics(
                new_topics=[NewTopic(name=topic, num_partitions=1, replication_factor=1)],
                validate_only=False,
            )
        except TopicAlreadyExistsError:
            pass
        finally:
            admin.close()

    def _roundtrip() -> str:
        payload = str(uuid.uuid4())
        producer = KafkaProducer(
            bootstrap_servers=brokers,
            client_id="python-health-check",
            retries=3,
            retry_backoff_ms=300,
        )
        try:
            producer.send(topic, value=payload.encode("utf-8")).get(timeout=10)
            producer.flush()
        finally:
            producer.close()

        consumer = KafkaConsumer(
            topic,
            bootstrap_servers=brokers,
            group_id=f"python-health-{payload[:8]}",
            auto_offset_reset="earliest",
            enable_auto_commit=False,
            consumer_timeout_ms=5000,
        )
        try:
            for message in consumer:
                if message.value.decode("utf-8") == payload:
                    return payload
        finally:
            consumer.close()
        raise RuntimeError("Payload not observed within timeout")

    def _check():
        _retry_node_ready(_ensure_topic)
        observed = _retry_node_ready(_roundtrip)
        return f"Produced and consumed payload {observed} on {topic}"

    return run_check(SERVICE, CLIENT, _check)
