# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a DigitalOcean App Platform development container that provides a complete local development environment mirroring production. It includes multi-language runtime support (Node.js, Python, Go, Rust) and local infrastructure services (PostgreSQL, MySQL, MongoDB, Valkey/Redis, Kafka, OpenSearch, MinIO) that replicate DigitalOcean managed services.

The repository contains:
- Dev container configuration for local development (`.devcontainer/`)
- Comprehensive test suite validating container health, runtimes, and service connectivity (`test-suite/`)

## Architecture

### Development Model

The dev container uses a "one dev box, many processes" model:
- **Main container (`app`)**: Single dev environment where all application code runs
- **Multiple processes**: Run frontend (`npm run dev`), backend (`uvicorn`), workers (`python worker.py`) as separate processes
- **Sidecar containers**: Infrastructure services (Postgres, Valkey, MinIO, etc.) run as separate containers

This architecture prioritizes:
- Fast rebuilds with hot reload and HMR
- Single volume for all code
- Easier debugging and AI assistance
- Production-like database/storage behavior

### Service Mapping

Production App Platform services map to local development as:
- Frontend/Backend/Worker Services → Processes in main container
- Managed Postgres → `postgres:5432` container
- Managed Valkey → `valkey:6379` container
- Spaces (S3) → `minio:9000` container (MinIO)
- Optional: MySQL, Kafka, MongoDB, OpenSearch

### Environment Configuration Pattern

Applications use `APP_ENV=local` to switch between local and production services:
- When `APP_ENV=local`: Use local container URLs (e.g., `postgresql://postgres:postgres@postgres:5432/devcontainer_db`)
- In production: Use App Platform environment variables (e.g., managed Postgres URL)

Key environment variables set by dev container:
- `DATABASE_URL`: PostgreSQL connection string
- `VALKEY_URL`: Valkey/Redis connection string
- `MINIO_ENDPOINT`, `MINIO_ACCESS_KEY`, `MINIO_SECRET_KEY`: MinIO/S3 access
- `MYSQL_URL`, `MONGODB_URL`, `KAFKA_BROKERS`, `OPENSEARCH_URL`: Optional services

## Development Commands

### Test Suite Execution

Run comprehensive 3-tier validation suite:
```bash
# From repository root, inside dev container
bash test-suite/run-suite.sh
```

Run individual test tiers:
```bash
# Tier 1: Container health verification
cd test-suite
bash setup-containers.sh          # Start all services
bash verify-containers.sh         # Verify container health and connectivity

# Tier 2: Runtime and package manager verification
cd test-suite
bash verify-runtimes.sh

# Tier 3: Service connectivity tests (language-specific)
# Python
cd test-suite/python
UV_CACHE_DIR=../.uv-cache uv sync
source .venv/bin/activate
python run_tests.py

# Node.js
cd test-suite/node
npm install
npm test

# Go
cd test-suite/go
bash run-tests.sh

# Rust
cd test-suite/rust
bash run-tests.sh
```

### Managing Dependencies

**Python** (uses UV):
```bash
cd test-suite/python
UV_CACHE_DIR=../.uv-cache uv add <package>
```

**Node.js** (uses npm):
```bash
cd test-suite/node
npm install <package>
```

**Go** (uses go modules):
```bash
cd test-suite/go
go get <package>
```

**Rust** (uses Cargo):
```bash
cd test-suite/rust
cargo add <crate>
```

### Runtime Management

All runtime versions are configured in `.devcontainer/.env`:

**Node.js** (via NVM):
- Multiple versions supported
- Default versions: 24, 22 (default: 24)
- Modify: `NODE_VERSIONS`, `NODE_DEFAULT_VERSION`

**Python** (via UV):
- Multiple versions supported
- Default versions: 3.12, 3.13 (default: 3.13)
- Modify: `PYTHON_VERSIONS`, `PYTHON_DEFAULT_VERSION`

**Go** (official binary):
- Single version only: 1.23.4
- Modify: `GOLANG_VERSION`

**Rust** (via rustup):
- Latest stable version

To disable a runtime, set `INSTALL_<RUNTIME>=false` in `.devcontainer/.env` and rebuild container.

### Service Management

**Controlling Which Services Start:**

Services are controlled by Docker Compose profiles via the `COMPOSE_PROFILES` variable in `.devcontainer/.env`:

```bash
# Edit .devcontainer/.env

# Only start default services (Postgres + MinIO)
COMPOSE_PROFILES=

# Start specific services
COMPOSE_PROFILES=valkey,mysql

# Start multiple optional services
COMPOSE_PROFILES=valkey,kafka,mongodb,opensearch
```

**Default Services (always start):**
- Postgres (port 5432)
- MinIO (ports 9000, 8900)

**Optional Services (require profile):**
- `valkey` - Valkey/Redis (port 6379)
- `mysql` - MySQL (port 3306)
- `kafka` - Kafka + Zookeeper (port 9092)
- `opensearch` - OpenSearch + Dashboards (ports 9200, 5601)
- `mongodb` - MongoDB (port 27017)

**Why Profiles?**
Profiles prevent overwhelming systems with limited RAM (8GB or less). Only services you explicitly enable will start, avoiding resource exhaustion. This uses native Docker Compose functionality - `COMPOSE_PROFILES` is an official environment variable that Docker Compose reads automatically.

**Service Versions:**

All service versions are configured in `.devcontainer/.env`:
- `POSTGRES_VERSION=18`
- `MYSQL_VERSION=9.5`
- `MONGODB_VERSION=8.2.1`
- `VALKEY_VERSION=9`
- `KAFKA_VERSION=7.9.4`
- `OPENSEARCH_VERSION=2`
- `MINIO_VERSION=latest`

### Container Operations

**Rebuild container after config changes**:
```bash
# In VS Code/Cursor: Command Palette → "Dev Containers: Rebuild Container"
# Or manually:
docker compose -f .devcontainer/docker-compose.yml build --no-cache
```

**Access services from host**:
Ports automatically forwarded to `localhost`:
- PostgreSQL: `localhost:5432`
- Valkey: `localhost:6379`
- MySQL: `localhost:3306`
- Kafka: `localhost:9092`
- OpenSearch: `localhost:9200`
- MinIO API: `localhost:9000`
- MinIO Console: `localhost:8900` (credentials: `minio`/`minio12345`)
- MongoDB: `localhost:27017`

## Important File Locations

### Configuration Files
- `.devcontainer/devcontainer.json`: Dev container definition, port forwarding, VS Code settings
- `.devcontainer/docker-compose.yml`: Main container and infrastructure services
- `.devcontainer/Dockerfile`: Container image with conditional runtime installation
- `.devcontainer/.env`: **Central configuration** for all runtime and service versions
- `.devcontainer/post-create.sh`: Initialization script for AI tools and doctl

### Test Suite Files
- `test-suite/run-suite.sh`: Master test runner (executes all 3 tiers)
- `test-suite/setup-containers.sh`: Service startup script
- `test-suite/verify-containers.sh`: Container health verification
- `test-suite/verify-runtimes.sh`: Runtime and package manager verification
- `test-suite/python/`: Python connectivity tests
- `test-suite/node/`: Node.js connectivity tests
- `test-suite/go/`: Go connectivity tests
- `test-suite/rust/`: Rust connectivity tests
- `test-suite/logs/`: Test execution logs (timestamped)

## Test Suite Structure

### 3-Tier Testing Architecture

**Tier 1: Container Health**
- Validates Docker Compose services are running
- Checks port accessibility and health
- Verifies network connectivity between containers

**Tier 2: Runtime Verification**
- Tests all installed runtime versions (Node.js v24, v22, Python 3.12, 3.13, Go 1.23.4, Rust stable)
- Validates package managers (npm, pip, go install, cargo)

**Tier 3: Service Connectivity**
- Language-specific tests for each service (PostgreSQL, MySQL, Valkey, Kafka, OpenSearch, MinIO, MongoDB)
- Each test creates real data and verifies read-back
- Tests automatically skip if service disabled or unreachable

### Extending the Test Suite

To add tests for a new service:
1. Add service to `.devcontainer/docker-compose.yml` with appropriate profile
2. Add `ENABLE_<SERVICE>` environment variable
3. Create test files for each runtime:
   - `test-suite/python/tests/test_<service>.py`
   - `test-suite/node/tests/<service>.js`
   - `test-suite/go/tests/<service>.go`
   - `test-suite/rust/src/tests/<service>.rs`
4. Follow existing `ServiceResult`/`Status` contract in test files
5. Add test execution to respective runner in each language's main file

## AI Tool Integration

The dev container comes pre-configured with:
- **Editor extensions**: Cursor, Claude Code, Copilot
- **CLI tools**: `doctl` (DigitalOcean), `gh` (GitHub), `claude`, `gemini-cli`, `codex`

AI config directories (`.claude`, `.gemini`, `.codex`) are mounted from host to persist authentication across rebuilds.

## Working with Application Code

### Multi-Service Development Pattern

For monorepos with multiple services, run processes in separate terminals:

**Terminal 1 (Frontend)**:
```bash
cd frontend
export APP_ENV=local
npm run dev
```

**Terminal 2 (Backend)**:
```bash
cd backend
export APP_ENV=local
uv run uvicorn app.main:app --reload --port 8000
```

**Terminal 3 (Worker)**:
```bash
cd analytics
export APP_ENV=local
python worker.py
```

All processes share the file system and can reach services at `postgres:5432`, `valkey:6379`, `minio:9000`, etc.

### Service Connection Examples

**PostgreSQL**:
```bash
# From app container
psql postgresql://postgres:postgres@postgres:5432/devcontainer_db
```

**MySQL**:
```bash
# From app container
mysql -h mysql -u mysql -p devcontainer_db
# Password: mysql
```

**MongoDB**:
```bash
# From app container
mongosh "mongodb://mongodb:mongodb@mongodb:27017/devcontainer_db"
```

**Valkey/Redis**:
```bash
# From app container (redis-cli available)
redis-cli -h valkey -p 6379
```

### MinIO/S3 Access

- **API**: `http://minio:9000` (from container) or `http://localhost:9000` (from host)
- **Console**: `http://localhost:8900` (from host)
- **Credentials**: Access Key: `minio`, Secret Key: `minio12345`

## Design Principles

1. **Single Source of Truth**: All versions and service configuration in `.devcontainer/.env`
2. **Resource-Conscious**: Docker Compose profiles prevent RAM exhaustion on limited systems
3. **Native Docker Compose**: Uses official `COMPOSE_PROFILES` environment variable with `env_file` for dev container compatibility
4. **No Custom Scripts**: Relies entirely on Docker Compose built-in features
5. **Build-Time Installation**: Runtimes installed during Docker build for fast startup
6. **Conditional Installation**: Skip unneeded runtimes for smaller images and faster builds
7. **Production Parity**: Local services behave like DigitalOcean managed services
8. **Zero Configuration**: Clone → Open → Run workflow (with sensible defaults)
9. **Isolated Environment**: Everything in containers, no host conflicts
