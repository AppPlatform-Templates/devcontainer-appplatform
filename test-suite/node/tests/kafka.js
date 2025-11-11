import { Kafka } from "kafkajs";
import { randomUUID } from "node:crypto";
import { gateCheck, Status } from "../lib/utils.js";

const SERVICE = "Kafka";
const CLIENT = "node-kafkajs";
const LOOPBACK_HOSTS = new Set(["localhost", "127.0.0.1"]);
const INTERNAL_BROKER = { host: "kafka", port: 29092 };

const normalizeBrokers = () => {
  const raw = process.env.KAFKA_BROKERS ?? "kafka:29092";
  const entries = raw.split(",").map((b) => b.trim()).filter(Boolean);

  const unique = [];
  const seen = new Set();
  for (const entry of entries) {
    const [rawHost = "kafka", rawPort = "29092"] = entry.split(":");
    const host = rawHost || "kafka";
    const port = Number(rawPort || "29092");
    const key = `${host}:${port}`;
    if (seen.has(key)) continue;
    unique.push({ host, port });
    seen.add(key);
  }

  const prioritized = [];
  const pushUnique = (broker) => {
    if (!prioritized.some((b) => b.host === broker.host && b.port === broker.port)) {
      prioritized.push(broker);
    }
  };

  // Always try the internal Docker network broker first; it exists in profiles that enable Kafka.
  pushUnique(INTERNAL_BROKER);

  for (const broker of unique) {
    if (!LOOPBACK_HOSTS.has(broker.host)) {
      pushUnique(broker);
    }
  }

  for (const broker of unique) {
    pushUnique(broker);
  }

  return prioritized.length ? prioritized : [INTERNAL_BROKER];
};

export const runTest = async () => {
  const prioritizedBrokers = normalizeBrokers();
  const brokerStrings = prioritizedBrokers.map(({ host, port }) => `${host}:${port}`);
  const [{ host, port }] = prioritizedBrokers;
  const topic = process.env.KAFKA_HEALTH_TOPIC ?? `health-check-${randomUUID()}`;

  const gate = await gateCheck({
    service: SERVICE,
    client: CLIENT,
    envFlag: "ENABLE_KAFKA",
    defaultEnabled: false,
    host,
    port,
  });
  if (gate) return gate;

  const kafka = new Kafka({ clientId: "node-health-check", brokers: brokerStrings });
  const admin = kafka.admin();
  await admin.connect();
  try {
    await admin.createTopics({
      waitForLeaders: true,
      topics: [{ topic, numPartitions: 1, replicationFactor: 1 }],
    });
  } catch (error) {
    const alreadyExists =
      error?.type === "TOPIC_ALREADY_EXISTS" || `${error?.message ?? error}`.includes("already exist");
    if (!alreadyExists) {
      throw error;
    }
  } finally {
    await admin.disconnect();
  }

  const payload = randomUUID();

  // Just produce a message successfully (sufficient for health check)
  const producer = kafka.producer();
  await producer.connect();
  await producer.send({
    topic,
    messages: [{ key: "health", value: payload }],
  });
  await producer.disconnect();

  return {
    service: SERVICE,
    client: CLIENT,
    status: Status.PASS,
    detail: `Produced message to topic ${topic}`,
  };
};
