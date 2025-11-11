import { performance } from "node:perf_hooks";
import { Status } from "./lib/utils.js";

const tests = [
  { module: "./tests/postgres.js", service: "PostgreSQL", client: "node-pg" },
  { module: "./tests/mysql.js", service: "MySQL", client: "node-mysql2" },
  { module: "./tests/valkey.js", service: "Valkey", client: "node-redis" },
  { module: "./tests/kafka.js", service: "Kafka", client: "node-kafkajs" },
  { module: "./tests/opensearch.js", service: "OpenSearch", client: "node-opensearch" },
  { module: "./tests/minio.js", service: "MinIO", client: "node-minio" },
];

const results = [];

console.log("Running Node.js connectivity checks...\n");

for (const spec of tests) {
  const start = performance.now();
  let outcome;
  try {
    const mod = await import(spec.module);
    outcome = await mod.runTest();
  } catch (error) {
    outcome = {
      service: spec.service,
      client: spec.client,
      status: Status.FAIL,
      detail: `${error}`,
    };
  }
  const durationMs = Math.round(performance.now() - start);
  const status = outcome.status ?? Status.FAIL;
  const service = outcome.service ?? spec.service;
  const client = outcome.client ?? spec.client;
  results.push({ ...outcome, status, service, client, durationMs });
  console.log(`[${status}] ${service.padEnd(12)} via ${client.padEnd(18)} (${durationMs} ms) -> ${outcome.detail}`);
}

const passed = results.filter((r) => r.status === Status.PASS).length;
const skipped = results.filter((r) => r.status === Status.SKIP).length;
const failed = results.filter((r) => r.status === Status.FAIL).length;

console.log(
  `\nNode.js summary: ${passed} passed, ${skipped} skipped, ${failed} failed`,
);

process.exit(failed > 0 ? 1 : 0);
