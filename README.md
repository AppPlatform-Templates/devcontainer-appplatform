# DigitalOcean App Platform Dev Container

> **Complete local development environment for DigitalOcean App Platform**
> Clone → Open → Run. Zero configuration needed.

A production-ready development container that provides DigitalOcean App Platform customers with a complete local environment mirroring production. Includes multi-language runtime support (Node.js, Python, Go, Rust) and local infrastructure services (PostgreSQL, MySQL, Valkey, Kafka, OpenSearch, MinIO, MongoDB) that replicate DigitalOcean managed services.

## ✨ Features

- **🎯 Zero Configuration** - Clone the repo, open in VS Code/Cursor, and start coding immediately
- **🔒 Isolated Environment** - Everything runs in containers with no conflicts on your host machine
- **🤖 AI-Ready** - Pre-configured for Cursor, Claude Code, Copilot, and other AI assistants
- **🚀 Fast Iteration** - Hot reload, HMR, and instant feedback loops
- **🔄 Production Parity** - Local services behave exactly like DigitalOcean managed services
- **📦 Multi-Language Support** - Node.js, Python, Go, and Rust runtimes included
- **💾 Complete Service Stack** - PostgreSQL, Valkey, MinIO, MySQL, Kafka, MongoDB, OpenSearch
- **⚡ Resource Conscious** - Profile-based service control for systems with limited RAM

## 🚀 Quick Start

### Prerequisites

- Docker Desktop or Docker Engine installed and running
- VS Code or Cursor installed
- Dev Containers extension (usually built-in)

### Get Started in 60 Seconds

1. **Clone this repository:**
   ```bash
   git clone https://github.com/AppPlatform-Templates/devcontainer-appplatform.git
   cd devcontainer-appplatform
   ```

2. **Open in VS Code or Cursor:**
   - Open the folder in your editor
   - Press `Cmd+Shift+P` (Mac) or `Ctrl+Shift+P` (Windows/Linux)
   - Select "Dev Containers: Reopen in Container"
   - Wait for the container to build (first time: 5-10 minutes)

3. **Start developing:**
   ```bash
   export APP_ENV=local
   # Your app automatically connects to local Postgres, Valkey, MinIO, etc.
   npm run dev        # or your frontend command
   python worker.py   # or your backend/worker command
   ```

**That's it!** You now have a complete local development environment that mirrors DigitalOcean App Platform.

## 🏗️ What's Included

### Language Runtimes (Configurable)

| Runtime | Default Versions | Installation Method |
|---------|------------------|---------------------|
| Node.js | 24, 22 (default: 24) | NVM |
| Python | 3.12, 3.13 (default: 3.13) | UV |
| Go | 1.23.4 | Official binary |
| Rust | Latest stable | rustup |

### Infrastructure Services

| Service | Port | Purpose | Default Status |
|---------|------|---------|----------------|
| **PostgreSQL** | 5432 | Database | ✅ Always On |
| **MinIO (S3)** | 9000, 8900 | Object Storage | ✅ Always On |
| Valkey/Redis | 6379 | Cache/Key-Value Store | Optional (profile: `valkey`) |
| MySQL | 3306 | Database | Optional (profile: `mysql`) |
| Kafka | 9092 | Message Broker | Optional (profile: `kafka`) |
| MongoDB | 27017 | NoSQL Database | Optional (profile: `mongodb`) |
| OpenSearch | 9200, 5601 | Search & Analytics | Optional (profile: `opensearch`) |

### Development Tools

- **DigitalOcean CLI** (`doctl`)
- **GitHub CLI** (`gh`)
- **AI CLI Tools** - Claude, Gemini, Codex
- **Database Clients** - psql, mysql, mongosh, redis-cli
- **VS Code/Cursor Extensions** - ESLint, Prettier, Python, Go, Rust Analyzer, and more

## 📖 Documentation

- **[.devcontainer/README.md](.devcontainer/README.md)** - Comprehensive dev container guide with setup, architecture, and troubleshooting
- **[.devcontainer/README-docker.md](.devcontainer/README-docker.md)** - Docker and Docker Compose command reference
- **[test-suite/README.md](test-suite/README.md)** - Test suite documentation and validation
- **[CLAUDE.md](CLAUDE.md)** - AI assistant integration guide for Claude Code

## 🎯 Architecture

### One Dev Box, Many Processes

This dev container uses a "one dev box, many processes" model optimized for rapid development:

**Main Container (`app`):**
- Single development environment where all application code runs
- Multiple processes: frontend (`npm run dev`), backend (`uvicorn`), workers (`python worker.py`)
- Fast rebuilds with hot reload and HMR
- Single volume for all code
- Easier debugging and AI assistance

**Sidecar Containers:**
- Infrastructure services (Postgres, Valkey, MinIO, etc.) run as separate containers
- Production-like database and storage behavior
- Isolated and easy to manage

### Service Mapping

| Production (App Platform) | Local Development |
|---------------------------|-------------------|
| Frontend Service | Process: `npm run dev` |
| Backend Service | Process: `uv run uvicorn ...` |
| Worker Service | Process: `python worker.py` |
| Managed Postgres | Container: `postgres:5432` |
| Managed Valkey | Container: `valkey:6379` |
| Spaces (S3) | Container: `minio:9000` |

## ⚙️ Configuration

### Controlling Which Services Start

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

**Why Profiles?**
- Prevents overwhelming systems with limited RAM (8GB or less)
- Only services you explicitly enable will start
- Uses native Docker Compose functionality

### Customizing Runtime Versions

All runtime and service versions are centralized in `.devcontainer/.env`:

```bash
# Disable a runtime
INSTALL_RUST=false

# Change Node versions
NODE_VERSIONS=20 18
NODE_DEFAULT_VERSION=20

# Use different Python versions
PYTHON_VERSIONS=3.11 3.12
PYTHON_DEFAULT_VERSION=3.12

# Change service versions
POSTGRES_VERSION=16
MYSQL_VERSION=9.5
```

After making changes, rebuild the container in VS Code/Cursor (Command Palette → "Rebuild Container").

## 🧪 Test Suite

This repository includes a comprehensive 3-tier test suite to validate the dev container setup:

**Tier 1: Container Health**
- Validates Docker Compose services are running
- Checks port accessibility and network connectivity

**Tier 2: Runtime Verification**
- Tests all installed runtime versions
- Validates package managers (npm, pip, go, cargo)

**Tier 3: Service Connectivity**
- Language-specific tests for each service
- Creates real data and verifies read-back
- Tests automatically skip if service disabled

**Run the full test suite:**
```bash
bash test-suite/run-suite.sh
```

See [test-suite/README.md](test-suite/README.md) for more details.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🆘 Support

- **Issues:** Report bugs or request features via [GitHub Issues](https://github.com/AppPlatform-Templates/devcontainer-appplatform/issues)
- **Documentation:** See the detailed guides in `.devcontainer/` and `test-suite/` directories
- **DigitalOcean Docs:** [App Platform Documentation](https://docs.digitalocean.com/products/app-platform/)

## 🎓 Next Steps

1. **Read the comprehensive guide:** [.devcontainer/README.md](.devcontainer/README.md)
2. **Configure your app:** Follow the refactoring guide to support `APP_ENV=local`
3. **Enable services you need:** Edit `.devcontainer/.env` and set `COMPOSE_PROFILES`
4. **Run the test suite:** Validate your setup with `bash test-suite/run-suite.sh`
5. **Start coding:** Your local environment now mirrors production!

---

**Built for DigitalOcean App Platform developers who want local development without the hassle.**
