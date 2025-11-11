# Dev Container Setup for DigitalOcean App Platform

This Dev Container gives DigitalOcean App Platform customers a complete local development environment that mirrors production—with zero configuration overhead. Clone the repo, open in VS Code/Cursor, and everything just works.

## Get Started in 60 Seconds

Refactor your app's configuration once to support local development. After that, every developer can clone the repo, open it in a Dev Container, and start coding immediately—all services automatically point to local containers.

### Step 1: Clone & Open

```bash
git clone <your-repo>
cd <your-repo>
# Open in VS Code or Cursor, then: "Reopen in Container"
```

### Step 2: Refactor Your Config (One Time)

Add a simple environment check to your configuration layer. The Dev Container automatically sets local service URLs when `APP_ENV=local`.

**TypeScript/Node.js:**

```typescript
const isLocal = process.env.APP_ENV === "local";

// DATABASE_URL is automatically set by the Dev Container (local) or App Platform (production)
// No refactoring needed - just use it directly!
export const DATABASE_URL = process.env.DATABASE_URL!;

// For Valkey: use VALKEY_URL (same env var for both local and production)
export const REDIS_URL = process.env.VALKEY_URL!;

// For object storage: use MINIO_ENDPOINT locally, SPACES_ENDPOINT in production
export const STORAGE_ENDPOINT = isLocal
  ? process.env.MINIO_ENDPOINT! // Local MinIO (set by Dev Container)
  : process.env.SPACES_ENDPOINT!; // DO Spaces (set by App Platform)
```

**Python:**

```python
import os

IS_LOCAL = os.getenv("APP_ENV") == "local"

# DATABASE_URL is automatically set by the Dev Container (local) or App Platform (production)
DATABASE_URL = os.environ["DATABASE_URL"]

# For Valkey: use VALKEY_URL (same env var for both local and production)
REDIS_URL = os.environ["VALKEY_URL"]

# For object storage: use MINIO_ENDPOINT locally, SPACES_ENDPOINT in production
STORAGE_ENDPOINT = (
    os.environ["MINIO_ENDPOINT"]  # Local MinIO
    if IS_LOCAL
    else os.environ["SPACES_ENDPOINT"]  # DO Spaces
)
```

**💡 Tip:** Use AI assistance (Cursor, Claude Code, Copilot) to help with this refactor:

> "Refactor this config to support APP_ENV=local mapping to local docker-compose services (postgres, valkey, minio). Use VALKEY_URL for both local and production. Use MINIO_ENDPOINT locally and SPACES_ENDPOINT in production."

### Step 3: Run Your App

```bash
export APP_ENV=local
npm run dev        # or your frontend command
uv run uvicorn app.main:app --reload  # or your backend command
python worker.py   # or your worker command
```

**That's it!** Your app now connects to:

- ✅ Local Postgres (instead of DO Managed Postgres)
- ✅ Local Valkey (instead of DO Managed Valkey)
- ✅ Local MinIO (instead of DO Spaces)
- ✅ All other services (MySQL, Kafka, MongoDB, OpenSearch) if enabled

When you deploy to App Platform, simply don't set `APP_ENV=local`, and it automatically uses your production DO-managed services.

---

## ✨ Why This Works

**The Magic:** This Dev Container automatically sets up environment variables that point to local services. When `APP_ENV=local`, your refactored config uses these local URLs. In production, it uses your App Platform environment variables.

**What You Get:**

- 🎯 **Zero Configuration:** Clone → Open → Run. No manual setup.
- 🔒 **Isolated Environment:** Everything runs in containers. No conflicts with your host machine.
- 🤖 **AI-Ready:** Cursor, Claude Code, Copilot, and other AI assistants work seamlessly inside the container.
- 🚀 **Fast Iteration:** Hot reload, HMR, and instant feedback—just like production, but local.
- 🔄 **Production Parity:** Local services behave like real DO-managed services.

---

## 🎯 Who This Is For

This Dev Container is designed for **DigitalOcean App Platform customers** who:

- Build multi-service apps (frontend + backend + workers)
- Use DO-managed services (Postgres, MySQL, Valkey, Spaces)
- Want rapid local development with AI assistance
- Need an isolated, reproducible development environment

If you want to develop locally without managing credentials, connection strings, or service setup, this is for you.

---

## 🏗️ Architecture: How It Works

### Mental Model: One Dev Box, Many Processes

**In Production (App Platform):**

- Frontend service (Next.js/Vite/React)
- Backend service (FastAPI/Express/etc.)
- Worker/analytics service (Python jobs, queues)
- Managed services (Postgres, Valkey, Spaces)

**In Local Development:**

- **One main dev container** = your dev machine
- **Multiple processes** run in that container:
  - `npm run dev` (frontend)
  - `uv run fastapi` (backend)
  - `python worker.py` (workers)
- **Infrastructure** runs as sidecar containers:
  - Postgres, MinIO, Valkey/Redis, MySQL, Kafka, MongoDB, OpenSearch

This model gives you:

- ✅ Fast rebuilds, hot reload, HMR
- ✅ All code on a single volume
- ✅ Easier debugging and AI assistance (everything in one place)
- ✅ Databases & storage behave like real services, but local

### Service Mapping

| Production (App Platform) | Local Development                       |
| ------------------------- | --------------------------------------- |
| Frontend Service          | Process: `npm run dev`                  |
| Backend Service           | Process: `uv run uvicorn ...`           |
| Worker Service            | Process: `python worker.py`             |
| Managed Postgres          | Container: `postgres:5432`              |
| Managed Valkey            | Container: `valkey:6379`                |
| Spaces (S3)               | Container: `minio:9000`                 |
| Managed MySQL             | Container: `mysql:3306` (optional)      |
| Kafka                     | Container: `kafka:9092` (optional)      |
| MongoDB                   | Container: `mongodb:27017` (optional)   |
| OpenSearch                | Container: `opensearch:9200` (optional) |

**Environment Variables:** The Dev Container automatically sets up connection strings. When `APP_ENV=local`, your refactored config uses these local URLs. In production, App Platform provides the DO-managed service URLs.

---

## 📋 Prerequisites

Before you start:

- ✅ Docker Desktop or Docker Engine installed and running
- ✅ VS Code or Cursor installed
- ✅ Dev Containers extension (usually built-in or available in marketplace)

---

## 🔧 Available Services

The Dev Container includes these services, controlled by profiles in `.env` file:

| Service               | Port  | Local URL                                                      | Environment Variable | Profile           |
| --------------------- | ----- | -------------------------------------------------------------- | -------------------- | ----------------- |
| **Postgres**          | 5432  | `postgresql://postgres:postgres@postgres:5432/devcontainer_db` | `DATABASE_URL`       | (always on)       |
| **MinIO (S3)**        | 9000  | `http://minio:9000`                                            | `MINIO_ENDPOINT`     | (always on)       |
| Valkey/Redis          | 6379  | `redis://valkey:6379`                                          | `VALKEY_URL`         | `valkey`          |
| MySQL                 | 3306  | `mysql://mysql:mysql@mysql:3306/devcontainer_db`               | `MYSQL_URL`          | `mysql`           |
| Kafka                 | 9092  | `kafka:9092`                                                   | `KAFKA_BROKERS`      | `kafka`           |
| MongoDB               | 27017 | `mongodb://mongodb:mongodb@mongodb:27017/devcontainer_db`      | `MONGODB_URL`        | `mongodb`         |
| OpenSearch            | 9200  | `http://opensearch:9200`                                       | `OPENSEARCH_URL`     | `opensearch`      |
| OpenSearch Dashboards | 5601  | `http://localhost:5601`                                        | -                    | (with opensearch) |

**MinIO Console:** Access at `http://localhost:8900` (username: `minio`, password: `minio12345`)

**Controlling Services:**

Services are controlled by the `COMPOSE_PROFILES` variable in `.devcontainer/.env`:

1. Edit `.devcontainer/.env`
2. Add profile names to `COMPOSE_PROFILES` (comma-separated):

   ```bash
   # Only start default services (Postgres + MinIO)
   COMPOSE_PROFILES=

   # Start Valkey and MySQL in addition to defaults
   COMPOSE_PROFILES=valkey,mysql

   # Start multiple optional services
   COMPOSE_PROFILES=valkey,kafka,mongodb
   ```

3. Rebuild the container

**Why Profiles?**

- Prevents overwhelming systems with limited RAM (8GB or less)
- Only starts services you actually need
- Postgres and MinIO (most common) always start, others are opt-in
- Uses native Docker Compose functionality - no custom scripts needed

---

## 🤖 AI & Tooling

The Dev Container comes pre-configured for AI-assisted development:

**Editor Extensions:**

- Cursor, Claude Code, Copilot (installed as editor extensions)
- All AI assistants work seamlessly inside the container

**CLI Tools Included:**

- `doctl` - DigitalOcean CLI
- `gh` - GitHub CLI
- `claude` - Claude CLI
- `gemini` - Gemini CLI
- `codex` - Codex CLI

**Credentials Setup:**

The Dev Container mounts AI config directories from your host (`.claude`, `.gemini`, `.codex`) to persist settings, history, and authentication across container rebuilds.

**One-Time Authentication (Inside Container):**

Due to macOS Keychain limitations, you need to authenticate inside the container the first time:

1. **Claude Code (uses your Claude subscription):**

   ```bash
   # Inside the devcontainer
   claude auth login
   ```

   This creates `~/.claude/.credentials.json` which persists via the mount. Uses your Claude Pro/Team/Enterprise subscription (no API billing).

2. **Gemini CLI (requires API key):**

   Add your Gemini API key to your host's shell profile (`~/.zshrc` or `~/.bash_profile`):

   ```bash
   export GEMINI_API_KEY="AI..."  # Get from https://aistudio.google.com/app/apikey
   ```

   Then reload: `source ~/.zshrc`

   The environment variable is automatically passed to the container.

3. **Codex (works automatically):**

   Already authenticated via mounted config directory - no action needed.

**Why This Works:**

- Config directories (`.claude`, `.gemini`, `.codex`) are mounted from your host
- Claude stores subscription auth in `.credentials.json` (persists via mount)
- Gemini uses API key (free tier available, passed as env var)
- Authentication persists across container rebuilds and recreations

---

## 📁 Files in This Folder

| File                    | Purpose                                                                   |
| ----------------------- | ------------------------------------------------------------------------- |
| `devcontainer.json`     | Defines the Dev Container: service, ports, VS Code settings, extensions   |
| `docker-compose.yml`    | Defines the main app container and all local infra containers             |
| `Dockerfile`            | Builds the main app container with conditional runtime installation       |
| `.env`                  | **Central configuration** for all runtime and service versions            |
| `post-create.sh`        | Initialization script that sets up AI tools, doctl, and displays versions |
| `setup-doctl-config.sh` | Configures DigitalOcean CLI with host credentials                         |
| `README.md`             | This file - comprehensive guide to using the dev container                |
| `README-docker.md`      | Docker and Docker Compose command reference                               |

---

## ⚙️ Customizing Runtimes & Versions

All runtime and service versions are centralized in `.devcontainer/.env`. This makes it easy to:

- Pin specific versions for consistency across your team
- Enable/disable runtimes to speed up builds
- Update versions without editing multiple files

### Available Runtimes

The container supports these language runtimes (all enabled by default):

| Runtime     | Installation Method | Version Control                                                                   |
| ----------- | ------------------- | --------------------------------------------------------------------------------- |
| **Node.js** | NVM                 | `NODE_VERSIONS`, `NODE_DEFAULT_VERSION` (installs: 24, 22; default: 24)           |
| **Python**  | UV                  | `PYTHON_VERSIONS`, `PYTHON_DEFAULT_VERSION` (installs: 3.12, 3.13; default: 3.13) |
| **Go**      | Official binary     | `GOLANG_VERSION` (single version: 1.23.4)                                         |
| **Rust**    | rustup              | Latest stable (single version)                                                    |

### How to Customize

**1. Edit `.env` to change versions:**

```bash
# Disable a runtime
INSTALL_RUST=false

# Change Node versions and default
NODE_VERSIONS=20 18
NODE_DEFAULT_VERSION=20

# Use different Python versions and set default
PYTHON_VERSIONS=3.11 3.12
PYTHON_DEFAULT_VERSION=3.12

# Change Go version (single version only)
GOLANG_VERSION=1.22.0
```

**2. Rebuild the container:**

```bash
# In VS Code/Cursor: Command Palette → "Rebuild Container"
# Or manually:
docker compose -f .devcontainer/docker-compose.yml build --no-cache
```

**3. Service versions are also in `.env`:**

```bash
POSTGRES_VERSION=18
MYSQL_VERSION=9.5
MONGODB_VERSION=8.2.1
KAFKA_VERSION=7.9.4
# ... etc
```

**Note:** CLI tools like `doctl`, `claude`, `gemini`, and `codex` always use the latest version for backward compatibility.

### Why This Design?

- **Single Source of Truth:** All versions in one file
- **Build-Time Installation:** Runtimes installed during Docker build (fast container startup)
- **Conditional Installation:** Skip runtimes you don't need (smaller images, faster builds)
- **Official Methods:** Uses NVM, UV, rustup, etc. following best practices

---

## 🎓 Advanced: Multi-Service Development

If you have a monorepo with multiple services:

**Terminal 1 (Frontend):**

```bash
cd frontend
export APP_ENV=local
npm run dev
```

**Terminal 2 (Backend):**

```bash
cd backend
export APP_ENV=local
uv run uvicorn app.main:app --reload --port 8000
```

**Terminal 3 (Worker):**

```bash
cd analytics
export APP_ENV=local
python worker.py
```

All processes share the same file system and can reach:

- `postgres:5432` (Postgres)
- `valkey:6379` (Valkey/Redis)
- `minio:9000` (MinIO)

---

## 🛠️ Validation Commands

Before running the devcontainer, validate the configuration:

### 1. Validate Docker Compose Configuration

```bash
docker compose -f .devcontainer/docker-compose.yml config --quiet
```

**Expected output:** Silent (no output) means configuration is valid

### 2. Validate DevContainer Configuration

```bash
npx --yes @devcontainers/cli read-configuration --workspace-folder .
```

**Expected output:** JSON configuration object with all merged settings

### 3. Validate Dockerfile Build

```bash
docker build --check -f .devcontainer/Dockerfile .devcontainer/
```

**Expected output:** "Check complete, no warnings found" or similar

---

## 🔧 Troubleshooting

### Container fails to start

1. Run all three validation commands above
2. Check Docker is running: `docker info`
3. Verify no port conflicts: `lsof -i :3000,5432,9000,8900` (Mac/Linux)
4. Check Docker logs: `docker compose -f .devcontainer/docker-compose.yml logs`

### Database connection issues

- PostgreSQL runs on `postgres:5432` inside the container network
- Use connection string: `postgresql://postgres:postgres@postgres:5432/devcontainer_db`
- Verify service is running: `docker compose -f .devcontainer/docker-compose.yml ps`

### MinIO storage issues

- Access MinIO console at `http://localhost:8900`
- Login: `minio` / `minio12345`
- Configure AWS SDK to use `http://minio:9000` as endpoint

### Credential mounting issues

- **doctl config**:
  - macOS: Verify `~/Library/Application Support/doctl/config.yaml` exists
  - Linux: Verify `~/.config/doctl/config.yaml` exists
  - If config is missing, run `doctl auth init` on your host machine
- **Other credentials**: Verify directories exist on host: `ls -la ~/.config/gh ~/.gemini ~/.codex ~/.claude`

### Service not starting

- Check if service profile is enabled in `.devcontainer/.env`
- Check service logs: `docker compose -f .devcontainer/docker-compose.yml logs <service-name>`
- Ensure service dependencies are met (e.g., Kafka requires Zookeeper)

### Port already in use

- Find process using port: `lsof -i :<port>` (Mac/Linux)
- Stop the conflicting service or change the port in `docker-compose.yml`

---

## ❓ FAQ

**Q: Why not mirror every service as its own dev container?**
A: For most development, one dev container with multiple processes is faster and simpler. You get hot reload, easier debugging, and AI assistance works better. Databases still run as separate containers for production parity.

**Q: Can I customize the services?**
A: Yes! Edit `.devcontainer/.env` and modify the `COMPOSE_PROFILES` variable to control which services start. To add new services, edit `docker-compose.yml`.

**Q: How do I disable a service to save resources?**
A: Edit `.devcontainer/.env` and remove the service's profile name from `COMPOSE_PROFILES`. Then rebuild the container.

**Q: What if I need production-like microservice topology?**
A: You can add a `docker-compose.override.yml` or use Kubernetes manifests. But for 90% of development, this simpler model is faster.

**Q: How do I access services from my host machine?**
A: Ports are automatically forwarded. Access services at `localhost:<port>` (e.g., `localhost:5432` for Postgres).

---

## 📚 Additional Resources

- [Dev Containers Documentation](https://containers.dev/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [DigitalOcean doctl Documentation](https://docs.digitalocean.com/reference/doctl/)
- [GitHub CLI Documentation](https://cli.github.com/manual/)
