import { randomUUID } from "node:crypto";
import { Client as MinioClient } from "minio";
import { gateCheck, Status } from "../lib/utils.js";

const SERVICE = "MinIO";
const CLIENT = "node-minio";

export const runTest = async () => {
  const host = process.env.MINIO_HOST ?? "minio";
  const port = Number(process.env.MINIO_PORT ?? "9000");
  const accessKey = process.env.MINIO_ACCESS_KEY ?? "minio";
  const secretKey = process.env.MINIO_SECRET_KEY ?? "minio12345";
  const bucket = process.env.MINIO_HEALTH_BUCKET ?? "health-checks";

  const gate = await gateCheck({
    service: SERVICE,
    client: CLIENT,
    envFlag: "ENABLE_MINIO",
    defaultEnabled: true,
    host,
    port,
  });
  if (gate) return gate;

  const client = new MinioClient({
    endPoint: host,
    port,
    useSSL: false,
    accessKey,
    secretKey,
  });

  const exists = await client.bucketExists(bucket);
  if (!exists) {
    await client.makeBucket(bucket);
  }

  const objectName = `health/${randomUUID()}.txt`;
  const payload = `node-minio-${randomUUID()}`;
  await client.putObject(bucket, objectName, payload);
  const stream = await client.getObject(bucket, objectName);
  const chunks = [];
  for await (const chunk of stream) {
    chunks.push(chunk);
  }
  const body = Buffer.concat(chunks).toString("utf-8");
  await client.removeObject(bucket, objectName);
  if (body !== payload) {
    throw new Error("payload mismatch");
  }

  return {
    service: SERVICE,
    client: CLIENT,
    status: Status.PASS,
    detail: `Uploaded and read ${objectName}`,
  };
};
