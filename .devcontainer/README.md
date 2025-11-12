# Dev Container Setup for DigitalOcean App Platform

This Dev Container gives DigitalOcean App Platform customers a complete local development environment that mirrors production—with little configuration overhead. Copy the `.devcontainer/` folder to your repository, open in VS Code/Cursor, and everything just works.

**Tested on:** macOS

## 🚀 Getting Started

**Important:** You don't clone this repository. Instead, you copy the `.devcontainer/` folder from this repository into your own application repository. This keeps everything self-contained and allows you to customize it for your specific needs.

### Path A: Starting a New Application (Greenfield)

Building a brand-new application? Here's the recommended workflow:

1. **Create your GitHub repository** (e.g., `my-awesome-app`)

2. **Clone your repository locally:**

   ```bash
   git clone https://github.com/yourusername/my-awesome-app.git
   cd my-awesome-app
   ```

3. **Get the `.devcontainer/` folder** from this repository. You have two options:

   **Option 1: Download as ZIP (Recommended)**

   ```bash
   # Download the repository as ZIP from GitHub
   # https://github.com/AppPlatform-Templates/devcontainer-appplatform/archive/refs/heads/main.zip

   # Extract and copy only the .devcontainer folder
   unzip devcontainer-appplatform-main.zip
   cp -r devcontainer-appplatform-main/.devcontainer .
   rm -rf devcontainer-appplatform-main devcontainer-appplatform-main.zip

   # Remove .git folder if present to avoid conflicts
   rm -rf .devcontainer/.git
   ```

   **Option 2: Use Git Sparse-Checkout**

   ```bash
   git clone --filter=blob:none --sparse https://github.com/AppPlatform-Templates/devcontainer-appplatform.git temp-devcontainer
   cd temp-devcontainer
   git sparse-checkout set .devcontainer
   cp -r .devcontainer ../.devcontainer
   cd ..
   rm -rf temp-devcontainer
   ```

4. **Configure services** (optional, before first build):

   - Edit `.devcontainer/.env` to enable only the services you need
   - See [Available Services](#-available-services) section below

5. **Open in dev container:**

   - Open your repository in VS Code or Cursor
   - Press `Cmd/Ctrl + Shift + P`
   - Select **"Dev Containers: Reopen in Container"**
   - First-time setup takes 5-10 minutes (downloads images, installs runtimes)

6. **Start building:** Your AI coding assistants (Claude Code, Cursor, Copilot) should be pre-configured and ready. 


### Path B: Adding Dev Container to Existing Application (Brownfield)

Already have an App Platform application? You can add local development with minimal refactoring:

1. **Get the `.devcontainer/` folder** using one of the methods from Path A above

2. **Copy `.devcontainer/` directory** to your existing repository root

3. **Open in dev container:**

   - Open your repository in VS Code or Cursor
   - Press `Cmd/Ctrl + Shift + P`
   - Select **"Dev Containers: Reopen in Container"**

4. **Refactor your configuration** to support `APP_ENV=local` pattern (one-time change):

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

5. **Run your app:**
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

## 🖥️ Platform Compatibility

**Tested on:** macOS

**Linux/Windows:** The dev container mounts credential directories from your host machine. Most paths work across platforms, but some require platform-specific configuration.

### What Works Automatically

**All platforms (macOS, Linux, Windows):**
- ✅ **Authentication is one-time on your HOST machine** - Authenticate once, works across all container rebuilds
- ✅ GitHub CLI (`~/.config/gh`) - Usually works on all platforms
- ✅ Claude Code (`~/.claude`) - Usually works on all platforms
- ✅ Gemini (`~/.gemini`) - Usually works on all platforms
- ✅ Codex (`~/.codex`) - Usually works on all platforms

**Platform-specific:**
- **doctl (macOS):** `~/Library/Application Support/doctl` (primary mount)
- **doctl (Linux):** `~/.config/doctl` (fallback mount, already supported)
- **doctl (Windows):** May require manual configuration inside container

### If Mounts Fail (Windows or custom paths)

If credential mounting doesn't work on your platform:

1. **Let the container mount fail gracefully** (it won't break the setup)
2. **Authenticate inside the container** (one-time setup):
   ```bash
   # Inside the dev container terminal
   doctl auth init
   gh auth login
   claude auth login
   ```
3. **Credentials persist via mounted volumes** - No need to re-authenticate on rebuilds

### Verify Before Starting

Check that credential directories exist on your host:

```bash
# macOS
ls -la ~/Library/Application\ Support/doctl ~/.config/gh ~/.gemini ~/.codex ~/.claude

# Linux
ls -la ~/.config/doctl ~/.config/gh ~/.gemini ~/.codex ~/.claude

# Windows (PowerShell)
ls $env:USERPROFILE\.config\gh, $env:USERPROFILE\.claude, $env:USERPROFILE\.gemini, $env:USERPROFILE\.codex
```

**Key Point:** Whether you authenticate on the host or inside the container, you only do it **once**. Credentials are mounted from your host and persist across container rebuilds.



## 🎯 Who This Is For

This Dev Container is designed for **DigitalOcean App Platform customers** who:

- Build multi-service apps (frontend + backend + workers)
- Use DO-managed services (Postgres, MySQL, Valkey, Spaces)
- Want rapid local development with AI assistance
- Need an isolated, reproducible development environment


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

## 🔐 Credentials & Mounted Volumes

**Important:** This dev container mounts certain credential directories from your host machine to enable seamless authentication with cloud services and AI tools. **These credentials remain on your host and are never shared in git repositories.**

### What Gets Mounted

The following directories are mounted from your host into the container:

**doctl (DigitalOcean CLI):**
- **Host path (macOS):** `~/Library/Application Support/doctl` → Container: `/tmp/doctl-config-mac` (readonly)
- **Host path (Linux):** `~/.config/doctl` → Container: `/tmp/doctl-config-linux` (readonly)
- During startup, credentials are copied to `/home/devcontainer/.config/doctl/` with proper permissions

**Claude Code:**
- **Host path:** `~/.claude` → Container: `/home/devcontainer/.claude` (read-write)
- Files: `.credentials.json`, `settings.json`, `.claude.json`
- Permissions set to 600 during startup for security

**GitHub CLI:**
- **Host path:** `~/.config/gh` → Container: `/home/devcontainer/.config/gh` (readonly)
- Authentication persists automatically via mount

**Gemini CLI:**
- **Host path:** `~/.gemini` → Container: `/home/devcontainer/.gemini` (read-write)
- Requires `GEMINI_API_KEY` environment variable on host

**Codex:**
- **Host path:** `~/.codex` → Container: `/home/devcontainer/.codex` (read-write)
- Authentication persists automatically via mount

### One-Time Authentication

**You only need to authenticate ONCE on your host machine.** After initial setup:
- Authentication persists across container rebuilds
- No need to re-authenticate when recreating containers
- Credentials stay on your host, never copied to git

**Initial Setup (first time only):**

```bash
# On your HOST machine (macOS/Linux), before opening dev container:

# 1. Authenticate with DigitalOcean
doctl auth init

# 2. Authenticate with GitHub
gh auth login

# 3. Authenticate with Claude Code
claude auth login

# 4. Set Gemini API key (add to ~/.bashrc or ~/.zshrc)
export GEMINI_API_KEY="your-api-key-here"
```

**Platform Notes:**
- **macOS:** All mounts work by default
- **Linux:** doctl path is `~/.config/doctl` (already supported). Other paths should work as-is.
- **Windows:** You may need to manually configure credentials inside the container if mounts fail. See [Platform Compatibility](#-platform-compatibility) section.

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

## 🔀 Multiple Projects: Avoiding Conflicts

If you're using dev containers for multiple projects, you need to be aware of potential conflicts:

### Container Name Conflicts

Each dev container uses hardcoded container names (`devcontainer-postgres`, `devcontainer-valkey`, etc.). **You cannot run multiple dev containers simultaneously** with the default configuration because container names will conflict.

**Solutions:**

1. **Stop containers from other projects** before starting a new one:

   ```bash
   # Recommended: Use docker compose down (stops and removes containers)
   cd /path/to/other/project
   docker compose -f .devcontainer/docker-compose.yml down

   # Or stop all devcontainer services at once
   docker ps -q --filter "name=devcontainer-" | xargs docker stop
   ```

2. **Modify container names** in `docker-compose.yml` to be unique per project:
   ```yaml
   # Change from:
   container_name: devcontainer-postgres
   # To:
   container_name: myproject-postgres
   ```

### Volume Naming and Isolation

Docker Compose prefixes volumes with your **project directory name** by default. This means:

- ✅ **Different directories = separate volumes** (safe): Projects in `/workspaces/project-a` and `/workspaces/project-b` automatically get separate volumes (`project-a_postgres_data` vs `project-b_postgres_data`)
- ⚠️ **Same directory name = shared volumes** (conflict risk): If you have multiple projects in directories with the same name (e.g., both named `app`), they will share the same database volumes

**To ensure isolation between projects:**

Set a unique `COMPOSE_PROJECT_NAME` in your `.devcontainer/.env` file:

```bash
# In .devcontainer/.env
COMPOSE_PROJECT_NAME=my-unique-project-name
```

This ensures each project gets its own set of volumes, even if directory names match.

**Example:**

```bash
# Project 1: .devcontainer/.env
COMPOSE_PROJECT_NAME=my-api-project

# Project 2: .devcontainer/.env
COMPOSE_PROJECT_NAME=my-frontend-project
```

Now both projects will have separate volumes: `my-api-project_postgres_data` and `my-frontend-project_postgres_data`.

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

### Container name already exists

If you see errors like "container name already exists" or "port already allocated":

1. **Stop and remove existing containers** from other projects:

   ```bash
   # Recommended: Use docker compose down from the other project
   cd /path/to/other/project
   docker compose -f .devcontainer/docker-compose.yml down

   # Or stop and remove all devcontainer services at once
   docker ps -q --filter "name=devcontainer-" | xargs docker stop
   docker ps -aq --filter "name=devcontainer-" | xargs docker rm
   ```

3. **Check for port conflicts:**

   ```bash
   # macOS/Linux
   lsof -i :5432,6379,9000,8900

   # Find and stop processes using those ports
   ```

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
- **Linux/Windows**: Mount paths may differ; see [Platform Compatibility](#-platform-compatibility) section

### Service not starting

- Check if service profile is enabled in `.devcontainer/.env`
- Check service logs: `docker compose -f .devcontainer/docker-compose.yml logs <service-name>`
- Ensure service dependencies are met (e.g., Kafka requires Zookeeper)

### Port already in use

- Find process using port: `lsof -i :<port>` (Mac/Linux)
- Stop the conflicting service or change the port in `docker-compose.yml`

### Volume conflicts between projects

If you suspect projects are sharing volumes:

1. **Check current volumes:**

   ```bash
   docker volume ls | grep postgres
   ```

2. **Set unique project name** in `.devcontainer/.env`:

   ```bash
   COMPOSE_PROJECT_NAME=my-unique-project-name
   ```

3. **Rebuild containers** to create new volumes with the new project name

---

## ❓ FAQ

**Q: Do I clone this repository?**
A: No! You copy the `.devcontainer/` folder from this repository into your own application repository. See [Getting Started](#-getting-started-two-paths) for detailed instructions.

**Q: Can I run multiple dev containers at the same time?**
A: Not with the default configuration. Container names are hardcoded and will conflict. You have two options:

1. Stop containers from other projects before starting a new one (see [Troubleshooting](#container-name-already-exists))
2. Modify container names in `docker-compose.yml` to be unique per project

**Q: Will my projects share the same database?**
A: It depends on your directory names and `COMPOSE_PROJECT_NAME` setting:

- Projects in different directories with different names = separate databases ✅
- Projects in directories with the same name = shared databases ⚠️
- Set `COMPOSE_PROJECT_NAME` in `.devcontainer/.env` to ensure isolation (see [Multiple Projects](#-multiple-projects-avoiding-conflicts))

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

**Q: Mount paths don't work on Linux/Windows - what do I do?**
A: The dev container is tested on macOS. For Linux/Windows, you may need to:

1. Update mount paths in `devcontainer.json` for your platform
2. Manually configure credentials inside the container (run `doctl auth init`, `gh auth login`, etc.)
3. See [Platform Compatibility](#-platform-compatibility) section for details

**Q: How do I stop the dev container? Does closing VS Code/Cursor stop it?**
A: **No, closing your editor does NOT stop the containers.** You must explicitly stop them:

**Recommended method (stops and removes containers):**
```bash
# From your project directory
docker compose -f .devcontainer/docker-compose.yml down
```

**Alternative methods:**
```bash
# Stop without removing (containers persist)
docker compose -f .devcontainer/docker-compose.yml stop

# Verify containers are stopped
docker ps | grep devcontainer

# Stop specific containers by name
docker stop devcontainer-postgres devcontainer-valkey devcontainer-minio

# Stop all devcontainer services at once
docker ps -q --filter "name=devcontainer-" | xargs docker stop
```

**When to use each:**
- Use `docker compose down` when completely done (frees memory and removes containers)
- Use `docker compose stop` for temporary pause (faster to restart later)
- Containers continue running in the background even after closing VS Code/Cursor

---

## 📚 Additional Resources

- [Dev Containers Documentation](https://containers.dev/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [DigitalOcean doctl Documentation](https://docs.digitalocean.com/reference/doctl/)
- [GitHub CLI Documentation](https://cli.github.com/manual/)
