from __future__ import annotations

import os
import uuid

from opensearchpy import OpenSearch

from utils import run_check, verify_service_gate

SERVICE = "OpenSearch"
CLIENT = "python-opensearch"


def run_test():
    host = os.getenv("OPENSEARCH_HOST", "opensearch")
    port = int(os.getenv("OPENSEARCH_PORT", "9200"))
    index = os.getenv("OPENSEARCH_HEALTH_INDEX", "health-checks")

    gate = verify_service_gate(SERVICE, CLIENT, "ENABLE_OPENSEARCH", False, host, port)
    if gate:
        return gate

    def _check():
        client = OpenSearch(
            hosts=[{"host": host, "port": port}],
            http_compress=True,
            use_ssl=False,
            verify_certs=False,
        )
        client.indices.create(
            index=index,
            body={
                "settings": {"number_of_shards": 1},
                "mappings": {"properties": {"message": {"type": "keyword"}}},
            },
            ignore=400,
        )
        doc_id = str(uuid.uuid4())
        payload = {"message": f"python-health-{doc_id}"}
        client.index(index=index, id=doc_id, body=payload, refresh=True)
        doc = client.get(index=index, id=doc_id)
        return f"Indexed doc {doc_id} (message={doc['_source']['message']})"

    return run_check(SERVICE, CLIENT, _check)
