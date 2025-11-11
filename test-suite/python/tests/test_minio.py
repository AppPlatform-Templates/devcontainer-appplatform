from __future__ import annotations

import os
import uuid
from io import BytesIO

from minio import Minio

from utils import run_check, verify_service_gate

SERVICE = "MinIO"
CLIENT = "python-minio"


def run_test():
    host = os.getenv("MINIO_HOST", "minio")
    port = int(os.getenv("MINIO_PORT", "9000"))
    access_key = os.getenv("MINIO_ACCESS_KEY", "minio")
    secret_key = os.getenv("MINIO_SECRET_KEY", "minio12345")
    bucket = os.getenv("MINIO_HEALTH_BUCKET", "health-checks")

    gate = verify_service_gate(SERVICE, CLIENT, "ENABLE_MINIO", True, host, port)
    if gate:
        return gate

    def _check():
        client = Minio(
            f"{host}:{port}",
            access_key=access_key,
            secret_key=secret_key,
            secure=False,
        )
        if not client.bucket_exists(bucket):
            client.make_bucket(bucket)
        object_name = f"health/{uuid.uuid4()}.txt"
        payload = f"minio-health-{uuid.uuid4()}"
        payload_bytes = payload.encode("utf-8")
        client.put_object(
            bucket,
            object_name,
            data=BytesIO(payload_bytes),
            length=len(payload_bytes),
            content_type="text/plain",
        )
        response = client.get_object(bucket, object_name)
        try:
            body = response.read().decode("utf-8")
        finally:
            response.close()
            response.release_conn()
        if body != payload:
            raise ValueError("payload mismatch")
        client.remove_object(bucket, object_name)
        return f"Uploaded and retrieved {object_name}"

    return run_check(SERVICE, CLIENT, _check)
