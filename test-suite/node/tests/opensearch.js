import { Client } from "@opensearch-project/opensearch";
import { randomUUID } from "node:crypto";
import { gateCheck, Status } from "../lib/utils.js";

const SERVICE = "OpenSearch";
const CLIENT = "node-opensearch";

export const runTest = async () => {
  const host = process.env.OPENSEARCH_HOST ?? "opensearch";
  const port = Number(process.env.OPENSEARCH_PORT ?? "9200");
  const index = process.env.OPENSEARCH_HEALTH_INDEX ?? "health-checks";

  const gate = await gateCheck({
    service: SERVICE,
    client: CLIENT,
    envFlag: "ENABLE_OPENSEARCH",
    defaultEnabled: false,
    host,
    port,
  });
  if (gate) return gate;

  const client = new Client({ node: `http://${host}:${port}` });

  await client.indices.create(
    {
      index,
      body: {
        settings: { number_of_shards: 1 },
        mappings: { properties: { message: { type: "keyword" } } },
      },
    },
    { ignore: [400] },
  );

  const docId = randomUUID();
  const message = `node-health-${docId}`;
  await client.index({
    index,
    id: docId,
    body: { message },
    refresh: true,
  });

  const { body } = await client.get({ index, id: docId });
  const source = body?._source;
  if (!source || source.message !== message) {
    throw new Error("document mismatch");
  }

  return {
    service: SERVICE,
    client: CLIENT,
    status: Status.PASS,
    detail: `Indexed doc ${docId}`,
  };
};
