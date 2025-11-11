from __future__ import annotations

import os
import socket
import time
from dataclasses import dataclass
from enum import Enum
from typing import Callable


class Status(str, Enum):
    PASS = "PASS"
    FAIL = "FAIL"
    SKIP = "SKIP"


@dataclass
class ServiceResult:
    """Simple container that keeps the result for a service check."""

    service: str
    client: str
    status: Status
    detail: str
    duration_ms: int

    def to_dict(self) -> dict:
        return {
            "service": self.service,
            "client": self.client,
            "status": self.status.value,
            "detail": self.detail,
            "duration_ms": self.duration_ms,
        }


def env_bool(name: str, default: bool) -> bool:
    raw = os.environ.get(name)
    if raw is None or raw == "":
        return default
    return raw.lower() in {"1", "true", "yes", "on"}


def wait_for_port(host: str, port: int, timeout: float = 2.0) -> bool:
    """Return True if a TCP port accepts a connection within timeout."""

    end = time.time() + timeout
    while time.time() < end:
        try:
            with socket.create_connection((host, port), timeout=0.5):
                return True
        except OSError:
            time.sleep(0.2)
    return False


def skip_result(service: str, client: str, reason: str) -> ServiceResult:
    return ServiceResult(
        service=service,
        client=client,
        status=Status.SKIP,
        detail=reason,
        duration_ms=0,
    )


def fail_result(service: str, client: str, reason: str) -> ServiceResult:
    return ServiceResult(
        service=service,
        client=client,
        status=Status.FAIL,
        detail=reason,
        duration_ms=0,
    )


def run_check(service: str, client: str, func: Callable[[], str]) -> ServiceResult:
    """Utility to execute a check and capture runtime + failure text."""

    start = time.time()
    try:
        detail = func()
        status = Status.PASS
    except Exception as exc:  # pragma: no cover - diagnostic path
        detail = f"{type(exc).__name__}: {exc}"
        status = Status.FAIL
    duration = int((time.time() - start) * 1000)
    return ServiceResult(service=service, client=client, status=status, detail=detail, duration_ms=duration)


def verify_service_gate(
    service: str,
    client: str,
    env_flag: str,
    default_enabled: bool,
    host: str,
    port: int | None,
) -> ServiceResult | None:
    """
    Return a skip result if the service is disabled or unreachable.
    Otherwise return None so the caller can run the test.
    """

    if not env_bool(env_flag, default_enabled):
        return skip_result(service, client, f"{env_flag}=false -> service intentionally disabled")

    if port is not None and not wait_for_port(host, port):
        return fail_result(service, client, f"{host}:{port} is not reachable")

    return None
