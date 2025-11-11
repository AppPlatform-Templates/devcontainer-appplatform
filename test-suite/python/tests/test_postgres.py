from __future__ import annotations

import os
import uuid

import psycopg2

from utils import run_check, verify_service_gate

SERVICE = "PostgreSQL"
CLIENT = "python-psycopg2"


def run_test():
    host = os.getenv("POSTGRES_HOST", "postgres")
    port = int(os.getenv("POSTGRES_PORT", "5432"))
    user = os.getenv("POSTGRES_USER", "postgres")
    password = os.getenv("POSTGRES_PASSWORD", "postgres")
    database = os.getenv("POSTGRES_DB", "devcontainer_db")

    gate = verify_service_gate(SERVICE, CLIENT, "ENABLE_POSTGRES", True, host, port)
    if gate:
        return gate

    def _check():
        conn = psycopg2.connect(host=host, port=port, user=user, password=password, dbname=database)
        conn.autocommit = True
        try:
            with conn.cursor() as cur:
                cur.execute(
                    """
                    CREATE TABLE IF NOT EXISTS health_check_events (
                        id UUID PRIMARY KEY,
                        source TEXT NOT NULL,
                        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
                    )
                    """
                )
                event_id = uuid.uuid4()
                cur.execute(
                    "INSERT INTO health_check_events (id, source) VALUES (%s, %s)",
                    (str(event_id), CLIENT),
                )
                cur.execute(
                    "SELECT COUNT(*) FROM health_check_events WHERE id = %s",
                    (str(event_id),),
                )
                count = cur.fetchone()[0]
            return f"Inserted row {event_id} (rows_found={count})"
        finally:
            conn.close()

    return run_check(SERVICE, CLIENT, _check)
