import mysql from "mysql2/promise";
import { randomUUID } from "node:crypto";
import { gateCheck, Status } from "../lib/utils.js";

const SERVICE = "MySQL";
const CLIENT = "node-mysql2";

export const runTest = async () => {
  const host = process.env.MYSQL_HOST ?? "mysql";
  const port = Number(process.env.MYSQL_PORT ?? "3306");
  const user = process.env.MYSQL_USER ?? "mysql";
  const password = process.env.MYSQL_PASSWORD ?? "mysql";
  const database = process.env.MYSQL_DATABASE ?? "devcontainer_db";

  const gate = await gateCheck({
    service: SERVICE,
    client: CLIENT,
    envFlag: "ENABLE_MYSQL",
    defaultEnabled: false,
    host,
    port,
  });
  if (gate) return gate;

  const connection = await mysql.createConnection({
    host,
    port,
    user,
    password,
    database,
  });

  try {
    await connection.execute(
      `CREATE TABLE IF NOT EXISTS health_check_events (
        id CHAR(36) PRIMARY KEY,
        source VARCHAR(64) NOT NULL,
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
      )`,
    );
    const insertedId = randomUUID();
    await connection.execute(`INSERT INTO health_check_events (id, source) VALUES (?, ?)`, [
      insertedId,
      CLIENT,
    ]);
    return {
      service: SERVICE,
      client: CLIENT,
      status: Status.PASS,
      detail: `Inserted row ${insertedId}`,
    };
  } finally {
    await connection.end();
  }
};
