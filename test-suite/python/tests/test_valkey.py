from __future__ import annotations

import os
import uuid

import redis

from utils import run_check, verify_service_gate

SERVICE = "Valkey"
CLIENT = "python-redis"


def run_test():
    host = os.getenv("VALKEY_HOST", os.getenv("REDIS_HOST", "valkey"))
    port = int(os.getenv("VALKEY_PORT", os.getenv("REDIS_PORT", "6379")))

    gate = verify_service_gate(SERVICE, CLIENT, "ENABLE_VALKEY", False, host, port)
    if gate:
        return gate

    def _check():
        client = redis.Redis(host=host, port=port, decode_responses=True)
        payload = str(uuid.uuid4())
        key = f"health:{payload}"
        client.set(key, payload, ex=30)
        value = client.get(key)
        client.delete(key)
        if value != payload:
            raise ValueError(f"unexpected payload {value}")
        return f"SET/GET on {key} succeeded"

    return run_check(SERVICE, CLIENT, _check)
