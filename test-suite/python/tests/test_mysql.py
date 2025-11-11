from __future__ import annotations

import os
import uuid

import mysql.connector

from utils import run_check, verify_service_gate

SERVICE = "MySQL"
CLIENT = "python-mysql-connector"


def run_test():
    host = os.getenv("MYSQL_HOST", "mysql")
    port = int(os.getenv("MYSQL_PORT", "3306"))
    user = os.getenv("MYSQL_USER", "mysql")
    password = os.getenv("MYSQL_PASSWORD", "mysql")
    database = os.getenv("MYSQL_DATABASE", "devcontainer_db")

    gate = verify_service_gate(SERVICE, CLIENT, "ENABLE_MYSQL", False, host, port)
    if gate:
        return gate

    def _check():
        conn = mysql.connector.connect(
            host=host,
            port=port,
            user=user,
            password=password,
            database=database,
        )
        try:
            cur = conn.cursor()
            cur.execute(
                """
                CREATE TABLE IF NOT EXISTS health_check_events (
                    id CHAR(36) PRIMARY KEY,
                    source VARCHAR(64) NOT NULL,
                    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
                )
                """
            )
            event_id = str(uuid.uuid4())
            cur.execute(
                "INSERT INTO health_check_events (id, source) VALUES (%s, %s)",
                (event_id, CLIENT),
            )
            conn.commit()
            cur.execute("SELECT COUNT(*) FROM health_check_events WHERE id = %s", (event_id,))
            count = cur.fetchone()[0]
            cur.close()
            return f"Inserted row {event_id} (rows_found={count})"
        finally:
            conn.close()

    return run_check(SERVICE, CLIENT, _check)
