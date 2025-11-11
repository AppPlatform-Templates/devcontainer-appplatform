import { randomUUID } from "node:crypto";
import { Client } from "pg";
import { gateCheck, Status } from "../lib/utils.js";

const SERVICE = "PostgreSQL";
const CLIENT = "node-pg";

export const runTest = async () => {
  const host = process.env.POSTGRES_HOST ?? "postgres";
  const port = Number(process.env.POSTGRES_PORT ?? "5432");
  const user = process.env.POSTGRES_USER ?? "postgres";
  const password = process.env.POSTGRES_PASSWORD ?? "postgres";
  const database = process.env.POSTGRES_DB ?? "devcontainer_db";

  const gate = await gateCheck({
    service: SERVICE,
    client: CLIENT,
    envFlag: "ENABLE_POSTGRES",
    defaultEnabled: true,
    host,
    port,
  });
  if (gate) return gate;

  const client = new Client({ host, port, user, password, database });
  await client.connect();

  try {
    await client.query(
      `CREATE TABLE IF NOT EXISTS health_check_events (
        id UUID PRIMARY KEY,
        source TEXT NOT NULL,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      )`
    );
    const insertedId = randomUUID();
    await client.query(
      `INSERT INTO health_check_events (id, source) VALUES ($1, $2)`,
      [insertedId, CLIENT],
    );
    return {
      service: SERVICE,
      client: CLIENT,
      status: Status.PASS,
      detail: `Inserted row ${insertedId}`,
    };
  } finally {
    await client.end();
  }
};
