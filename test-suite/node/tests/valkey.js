import { randomUUID } from "node:crypto";
import { createClient } from "redis";
import { gateCheck, Status } from "../lib/utils.js";

const SERVICE = "Valkey";
const CLIENT = "node-redis";

export const runTest = async () => {
  const host = process.env.VALKEY_HOST ?? process.env.REDIS_HOST ?? "valkey";
  const port = Number(process.env.VALKEY_PORT ?? process.env.REDIS_PORT ?? "6379");

  const gate = await gateCheck({
    service: SERVICE,
    client: CLIENT,
    envFlag: "ENABLE_VALKEY",
    defaultEnabled: false,
    host,
    port,
  });
  if (gate) return gate;

  const client = createClient({ socket: { host, port } });
  await client.connect();

  try {
    const payload = randomUUID();
    const key = `health:${payload}`;
    await client.set(key, payload, { EX: 30 });
    const stored = await client.get(key);
    await client.del(key);
    if (stored !== payload) {
      throw new Error("payload mismatch");
    }
    return {
      service: SERVICE,
      client: CLIENT,
      status: Status.PASS,
      detail: `SET/GET succeeded for ${key}`,
    };
  } finally {
    await client.disconnect();
  }
};
