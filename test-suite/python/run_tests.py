from __future__ import annotations

import importlib
import sys
from pathlib import Path

from utils import ServiceResult, Status

TEST_MODULES = [
    "tests.test_postgres",
    "tests.test_mysql",
    "tests.test_valkey",
    "tests.test_kafka",
    "tests.test_opensearch",
    "tests.test_minio",
]


def main() -> int:
    root = Path(__file__).resolve().parent
    sys.path.insert(0, str(root))

    results: list[ServiceResult] = []
    print("Running Python connectivity checks...\n")
    for module_name in TEST_MODULES:
        module = importlib.import_module(module_name)
        result: ServiceResult = module.run_test()
        results.append(result)
        print(
            f"[{result.status.value}] {result.service:12s} via {result.client:22s}"
            f" ({result.duration_ms} ms) -> {result.detail}"
        )

    failures = [r for r in results if r.status is Status.FAIL]
    skipped = [r for r in results if r.status is Status.SKIP]
    print(
        f"\nPython summary: {len(results) - len(failures) - len(skipped)} passed, "
        f"{len(skipped)} skipped, {len(failures)} failed"
    )
    return 0 if not failures else 1


if __name__ == "__main__":
    raise SystemExit(main())
