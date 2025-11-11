# Devcontainer Validation Suite

This suite provides comprehensive automated validation for the DigitalOcean App Platform dev container. It verifies that all runtimes, package managers, and services are correctly installed, configured, and operational.

## 3-Tier Testing Architecture

### **Tier 1: Container Health Verification**
Validates that all Docker Compose services are running and healthy:
- Container status and port accessibility
- Service health checks (PostgreSQL, MySQL, Valkey, Kafka, OpenSearch, MinIO, MongoDB)
- Network connectivity from app container to services
- Resource usage monitoring

Scripts: `setup-containers.sh`, `verify-containers.sh`

### **Tier 2: Runtime & Package Manager Verification**
Tests all installed runtime versions and package managers:
- **Node.js**: v24, v22 (via NVM)
- **Python**: 3.12, 3.13 (via UV)
- **Go**: 1.23.4
- **Rust**: stable
- Package manager tests: npm, uv, go install, cargo

Script: `verify-runtimes.sh`

### **Tier 3: Service Connectivity Tests**
Validates that each runtime can connect to and perform operations on all services:
- **Python tests** (`python/`) – PostgreSQL, MySQL, Valkey, Kafka, OpenSearch, MinIO
- **Node.js tests** (`node/`) – Same services using JavaScript libraries
- **Go tests** (`go/`) – Same services using Go libraries
- **Rust tests** (`rust/`) – Same services using Rust crates

Each test creates real data (table rows, Redis keys, Kafka messages, documents, objects) and verifies it can be read back. Optional services automatically skip if their `ENABLE_*` flag is `false` or port is unreachable.

## Running the suite

```bash
# from repo root, inside the devcontainer
bash test-suite/run-suite.sh

# optional: stop immediately after the first failing tier
STOP_ON_FAILURE=1 bash test-suite/run-suite.sh
```

The runner will:

- write consolidated logs under `test-suite/logs/run-<timestamp>.log`
- manage Python dependencies via `uv sync` (env stored in `test-suite/python/.venv`)
- install Node dependencies on-demand
- exit with a non-zero code if any check fails
- respect `STOP_ON_FAILURE=1` to exit right after the first failure so you can inspect the partial log before continuing

## One-off execution

Run individual test tiers or specific runtime tests:

**Tier 1 - Container Health:**
```bash
cd test-suite
bash setup-containers.sh          # Start all services
bash verify-containers.sh         # Verify container health
```

**Tier 2 - Runtime Verification:**
```bash
cd test-suite
bash verify-runtimes.sh           # Test all runtimes and package managers (npm / uv / go / cargo)
```

> Rust/Kafka clients compile small native shims. Ensure the base devcontainer image includes
> `build-essential`, `pkg-config`, `libssl-dev`, `cmake`, and `zlib1g-dev` so the Rust suite
> can build `librdkafka` without installing packages at runtime.

**Tier 3 - Service Connectivity:**
```bash
# Python only
cd test-suite/python
UV_CACHE_DIR=../.uv-cache uv sync
source .venv/bin/activate
python run_tests.py

# Node.js only
cd test-suite/node
npm install
npm test

# Go only
cd test-suite/go
bash run-tests.sh

# Rust only
cd test-suite/rust
bash run-tests.sh
```

## Managing Dependencies

**Python:** `cd test-suite/python && UV_CACHE_DIR=../.uv-cache uv add <package>`

**Node.js:** `cd test-suite/node && npm install <package>`

**Go:** `cd test-suite/go && go get <package>`

**Rust:** `cd test-suite/rust && cargo add <crate>`

## Extending the test suite

To add a new service:

1. Add service to `.devcontainer/docker-compose.yml` with appropriate profile
2. Add `ENABLE_<SERVICE>` environment variable
3. Create test files for each runtime:
   - `python/tests/test_<service>.py`
   - `node/tests/<service>.js`
   - `go/tests/<service>.go`
   - `rust/src/tests/<service>.rs`
4. Follow the existing `ServiceResult`/`Status` contract
5. Add test to respective runner in each language's main file

## File Organization

```
test-suite/
├── run-suite.sh              # Master test runner (3-tier execution)
├── setup-containers.sh       # Start Docker Compose services
├── verify-containers.sh      # Verify container health
├── verify-runtimes.sh        # Verify runtimes & package managers
├── python/                   # Python connectivity tests
├── node/                     # Node.js connectivity tests
├── go/                       # Go connectivity tests
├── rust/                     # Rust connectivity tests
└── logs/                     # Test execution logs
```

**Note:** `setup-containers.sh` and `verify-containers.sh` were moved from `.devcontainer/` to `test-suite/` as they are test utilities, not dev container setup scripts.
