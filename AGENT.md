# AGENT.md - AI Assistant Operations Guide

This file provides instructions for AI assistants (Claude Code, Cursor, GitHub Copilot, etc.) to help users set up, configure, and manage this DigitalOcean App Platform dev container with minimal human intervention.

## Purpose

Enable AI assistants to autonomously:
1. Configure the dev container based on user requirements
2. Set up services and runtimes through `.env` configuration
3. Guide users through the setup handoff process
4. Troubleshoot common issues when they arise

**Important:** AI assistants handle file operations and configuration. Users handle IDE/UI interactions (opening in dev container).

---

## Two Setup Scenarios: Greenfield vs. Brownfield

There are two fundamentally different workflows depending on whether the user is starting fresh or adding dev container to existing code.

### Scenario 1: Greenfield (New Repository/Application)

**Context:** User wants to build a brand new application from scratch.

**AI Approach:**
1. **Download `.devcontainer/` folder** to the new repository
2. **Infer requirements** from user's description (don't ask unnecessary questions)
3. **Configure dev container automatically** based on inference
4. **Build application code with `APP_ENV=local` pattern from day one**
5. **Zero refactoring needed** - code works locally and in production

**Example User Request:**
> "Build me a Next.js app with user authentication and file uploads"

**Step 1: Download Dev Container Configuration**

```bash
# Download the ZIP file from GitHub
curl -L -o devcontainer-appplatform.zip https://github.com/AppPlatform-Templates/devcontainer-appplatform/archive/refs/heads/main.zip

# Extract and copy .devcontainer folder
unzip -q devcontainer-appplatform.zip
cp -r devcontainer-appplatform-main/.devcontainer .
rm -rf devcontainer-appplatform-main devcontainer-appplatform.zip .devcontainer/.git

# Verify
ls -la .devcontainer/
```

**Step 2: AI Inference from User Request**

- Frontend: Next.js → **Node.js** runtime needed
- Authentication: User sessions → **PostgreSQL** (users table) + **Valkey** (sessions)
- File uploads: Object storage → **MinIO** (S3-compatible)

**Step 3: Auto-Configure `.devcontainer/.env`**
```bash
INSTALL_NODEJS=true
INSTALL_PYTHON=false
INSTALL_GOLANG=false
INSTALL_RUST=false

COMPOSE_PROFILES=valkey
```

**Step 4: Write Code That Works Everywhere:**
```typescript
// lib/db.ts - Built with local-first approach
const isLocal = process.env.APP_ENV === 'local';

// DATABASE_URL is set by dev container locally, App Platform in production
export const db = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: isLocal ? false : { rejectUnauthorized: false }
});

// lib/storage.ts - S3/MinIO abstraction
import { S3Client } from '@aws-sdk/client-s3';

const isLocal = process.env.APP_ENV === 'local';

export const s3 = new S3Client({
  endpoint: isLocal
    ? process.env.MINIO_ENDPOINT      // Local: http://minio:9000
    : process.env.SPACES_ENDPOINT,    // Production: DigitalOcean Spaces
  credentials: {
    accessKeyId: isLocal ? process.env.MINIO_ACCESS_KEY! : process.env.SPACES_KEY!,
    secretAccessKey: isLocal ? process.env.MINIO_SECRET_KEY! : process.env.SPACES_SECRET!
  },
  region: isLocal ? 'us-east-1' : process.env.SPACES_REGION,
  forcePathStyle: isLocal, // Required for MinIO
});
```

**Key Point:** No refactoring needed later because code is built correctly from the start.

---

### Scenario 2: Brownfield (Existing Repository/Application)

**Context:** User has an existing application already deployed to App Platform and wants local development.

**AI Approach:**
1. **Download `.devcontainer/` folder** to the existing repository
2. **Analyze codebase** to detect languages, databases, and services
3. **Identify files that need refactoring** (hardcoded production URLs)
4. **Ask permission** before modifying code
5. **Refactor configuration** to support `APP_ENV=local` pattern
6. **Configure dev container** based on detected requirements

**Example User Request:**
> "Add dev container support to my existing Next.js app"

**AI Analysis Workflow:**

#### Step 0: Download Dev Container Configuration

First, check if `.devcontainer/` already exists:

```bash
ls -la .devcontainer/
```

If it doesn't exist, download it:

```bash
# Download the ZIP file from GitHub
curl -L -o devcontainer-appplatform.zip https://github.com/AppPlatform-Templates/devcontainer-appplatform/archive/refs/heads/main.zip

# Extract and copy .devcontainer folder
unzip -q devcontainer-appplatform.zip
cp -r devcontainer-appplatform-main/.devcontainer .
rm -rf devcontainer-appplatform-main devcontainer-appplatform.zip .devcontainer/.git

# Verify
ls -la .devcontainer/
```

#### Step 1: Detect Languages
```bash
# Check for package managers and language indicators
ls package.json         # Node.js
ls requirements.txt     # Python
ls pyproject.toml       # Python (modern)
ls go.mod              # Go
ls Cargo.toml          # Rust
```

#### Step 2: Detect Dependencies and Services
```bash
# Search for database clients
grep -r "import.*pg\|from.*pg\|require.*pg" . --include="*.js" --include="*.ts"
grep -r "import.*mysql\|from.*mysql" . --include="*.js" --include="*.ts"
grep -r "import.*mongodb\|mongoose" . --include="*.js" --include="*.ts"
grep -r "import.*psycopg2\|import.*asyncpg" . --include="*.py"

# Search for Redis/cache clients
grep -r "import.*ioredis\|import.*redis" . --include="*.js" --include="*.ts"
grep -r "import.*redis\|from.*redis" . --include="*.py"

# Search for object storage
grep -r "@aws-sdk.*s3\|aws-sdk.*S3" . --include="*.js" --include="*.ts"
grep -r "import.*boto3\|from.*boto3" . --include="*.py"

# Search for Kafka
grep -r "kafkajs\|kafka-node" . --include="*.js" --include="*.ts"
grep -r "kafka-python\|confluent_kafka" . --include="*.py"

# Search for OpenSearch/Elasticsearch
grep -r "@opensearch\|elasticsearch" . --include="*.js" --include="*.ts"
grep -r "opensearch-py\|elasticsearch" . --include="*.py"
```

#### Step 3: Present Analysis to User
```
Analysis of your codebase:

Detected:
✅ Node.js (package.json found)
✅ PostgreSQL (found: lib/db.ts imports 'pg')
✅ Redis (found: lib/cache.ts imports 'ioredis')
✅ AWS S3 (found: lib/storage.ts imports '@aws-sdk/client-s3')

Configuration files that need refactoring:
1. lib/db.ts - Currently uses production-only DATABASE_URL
2. lib/cache.ts - Currently uses production-only REDIS_URL
3. lib/storage.ts - Currently uses AWS S3, needs MinIO support for local

I'll configure the dev container with:
- Node.js runtime
- PostgreSQL service
- Valkey/Redis service
- MinIO service (S3-compatible)

May I proceed with refactoring these 3 files to support local development?
```

#### Step 4: Refactor Configuration Files (With Permission)

See the comprehensive [Refactoring Patterns](#refactoring-patterns-by-framework) section below.

---

## Setup Workflow

### Phase 1: Pre-Setup Configuration (AI-Assisted)

**Goal:** Configure `.devcontainer/` for the user's specific needs without requiring manual `.env` editing.

#### Step 1: Verify Prerequisites

Before starting, confirm the user has:
- Docker Desktop installed and running
- VS Code or Cursor editor installed
- Dev Containers extension (usually built-in in modern versions)

Ask the user to verify:
```bash
docker --version
docker compose version
```

If Docker is not installed, direct them to: https://www.docker.com/products/docker-desktop

#### Step 2: Download and Copy `.devcontainer/` to User's Repository

**Check if `.devcontainer/` already exists:**

```bash
# AI: Run this first to check
ls -la .devcontainer/
```

**If `.devcontainer/` does NOT exist, download it:**

AI assistants should use the Bash tool to execute these commands in the user's repository:

```bash
# Download the ZIP file from GitHub
curl -L -o devcontainer-appplatform.zip https://github.com/AppPlatform-Templates/devcontainer-appplatform/archive/refs/heads/main.zip

# Extract the ZIP file
unzip -q devcontainer-appplatform.zip

# Copy only the .devcontainer folder to current directory
cp -r devcontainer-appplatform-main/.devcontainer .

# Clean up downloaded files
rm -rf devcontainer-appplatform-main devcontainer-appplatform.zip

# Remove .git folder if present to avoid conflicts
rm -rf .devcontainer/.git

# Verify the copy was successful
ls -la .devcontainer/
```

**Expected output after successful copy:**
```
.devcontainer/
├── .env
├── devcontainer.json
├── docker-compose.yml
├── Dockerfile
├── post-create.sh
├── setup-doctl-config.sh
└── README.md
```

**If `.devcontainer/` already exists:**

Skip this step and proceed to Step 3. The user already has the dev container configuration.

#### Step 3: Interview User About Requirements

Ask the user which languages and services they need. Use these questions:

**Runtime Languages:**
- "Which programming languages will you use?"
  - Node.js (versions 24, 22 by default)
  - Python (versions 3.13, 3.12 by default)
  - Go (version 1.23.4)
  - Rust (latest stable)

**Services:**
- "Which infrastructure services do you need?"
  - PostgreSQL (always enabled by default)
  - MinIO/S3 (always enabled by default)
  - Valkey/Redis
  - MySQL
  - MongoDB
  - Kafka
  - OpenSearch

**Resource Constraints:**
- "How much RAM does your system have?"
  - If ≤8GB, recommend only essential services (Postgres + MinIO + one optional)
  - If >8GB, can enable multiple services

#### Step 4: Configure `.devcontainer/.env`

Based on user responses, modify `.devcontainer/.env`:

**Example 1: Node.js + Python app with Postgres and Valkey**
```bash
# Runtimes
INSTALL_NODEJS=true
INSTALL_PYTHON=true
INSTALL_GOLANG=false
INSTALL_RUST=false

# Services (via COMPOSE_PROFILES)
COMPOSE_PROFILES=valkey
```

**Example 2: Full-stack app with all services (16GB+ RAM)**
```bash
# Runtimes
INSTALL_NODEJS=true
INSTALL_PYTHON=true
INSTALL_GOLANG=true
INSTALL_RUST=true

# Services
COMPOSE_PROFILES=valkey,mysql,kafka,opensearch,mongodb
```

**Example 3: Minimal Python app with only Postgres (8GB RAM)**
```bash
# Runtimes
INSTALL_NODEJS=false
INSTALL_PYTHON=true
INSTALL_GOLANG=false
INSTALL_RUST=false

# Services
COMPOSE_PROFILES=
```

**Key Configuration Variables:**

| Variable | Purpose | Example Values |
|----------|---------|----------------|
| `INSTALL_NODEJS` | Enable Node.js runtime | `true` / `false` |
| `INSTALL_PYTHON` | Enable Python runtime | `true` / `false` |
| `INSTALL_GOLANG` | Enable Go runtime | `true` / `false` |
| `INSTALL_RUST` | Enable Rust runtime | `true` / `false` |
| `COMPOSE_PROFILES` | Enable optional services | `valkey,mysql,kafka` |
| `NODE_VERSIONS` | Node.js versions to install | `24 22` |
| `PYTHON_VERSIONS` | Python versions to install | `3.13 3.12` |

**Service Profiles:**
- `valkey` - Valkey/Redis (port 6379)
- `mysql` - MySQL (port 3306)
- `mongodb` - MongoDB (port 27017)
- `kafka` - Kafka + Zookeeper (port 9092)
- `opensearch` - OpenSearch + Dashboards (ports 9200, 5601)

**Default Services (always enabled):**
- PostgreSQL (port 5432)
- MinIO (ports 9000, 8900)

#### Step 5: Explain Configuration to User

After modifying `.env`, provide a summary:

```
I've configured your dev container with:

Runtimes:
- ✅ Node.js (v24, v22)
- ✅ Python (3.13, 3.12)
- ❌ Go (disabled)
- ❌ Rust (disabled)

Services:
- ✅ PostgreSQL (always enabled)
- ✅ MinIO (always enabled)
- ✅ Valkey/Redis (enabled via profile)
- ❌ MySQL (disabled)
- ❌ Kafka (disabled)
- ❌ MongoDB (disabled)
- ❌ OpenSearch (disabled)

This configuration is optimized for your 8GB RAM system.
```

#### Step 6: Commit Configuration (Optional)

If user wants to save the configuration:
```bash
git add .devcontainer/
git commit -m "feat: add dev container configuration

- Enable Node.js and Python runtimes
- Enable PostgreSQL, MinIO, and Valkey services
- Configure for 8GB RAM system"
```

---

### Phase 2: Handoff to User (AI Instructs)

After configuration is complete, provide clear instructions:

```
✅ Your dev container is configured and ready!

Next steps:
1. Open this repository in VS Code or Cursor
2. Press Cmd/Ctrl + Shift + P (Command Palette)
3. Type "Dev Containers: Reopen in Container"
4. Select that option
5. Wait 5-10 minutes for first-time setup (downloads images, installs runtimes)

Once the container is running, come back and I can help you:
- Verify all services are working
- Run the test suite
- Connect to databases
- Start building your application

The container will automatically set these environment variables:
- DATABASE_URL (PostgreSQL connection)
- VALKEY_URL (Redis connection)
- MINIO_ENDPOINT, MINIO_ACCESS_KEY, MINIO_SECRET_KEY (S3 storage)
```

**Important:** Do NOT attempt to run `docker compose up` or open the dev container programmatically. This is a UI action the user must perform.

---

### Phase 3: Post-Setup Verification (Optional - On Demand)

Run this phase only if:
- User explicitly requests validation
- User reports issues with services or runtimes
- User wants to verify everything is working before starting development

#### Run Test Suite

```bash
# From repository root, inside the dev container
bash test-suite/run-suite.sh
```

#### Interpret Test Results

**Tier 1: Container Health**
- ✅ All enabled services should show "healthy" status
- ❌ If service is unreachable, check if it's enabled in `COMPOSE_PROFILES`

**Tier 2: Runtime Verification**
- ✅ All enabled runtimes should pass version checks
- ❌ If runtime fails, check `INSTALL_<RUNTIME>` in `.env`

**Tier 3: Service Connectivity**
- ✅ All enabled services should accept connections and perform CRUD operations
- ❌ If connection fails, verify service is running: `docker ps | grep devcontainer`

#### Common Test Failures and Fixes

**Failure: "Service not reachable"**
```bash
# Check if service is running
docker ps | grep devcontainer-<service>

# If not running, check COMPOSE_PROFILES
cat .devcontainer/.env | grep COMPOSE_PROFILES

# Rebuild container if needed
# (User must do this via VS Code Command Palette: "Dev Containers: Rebuild Container")
```

**Failure: "Runtime not found"**
```bash
# Check if runtime is enabled
cat .devcontainer/.env | grep INSTALL_<RUNTIME>

# If should be enabled but isn't, rebuild container
```

**Failure: "Port conflict"**
```bash
# Find conflicting process
lsof -i :<port>  # macOS/Linux
netstat -ano | findstr :<port>  # Windows

# Stop conflicting container
docker ps -q --filter "name=devcontainer-" | xargs docker stop
```

---

## Refactoring Patterns by Framework

This section provides comprehensive patterns for refactoring existing applications to support local dev container development. **Always ask permission before modifying user code.**

### General Refactoring Principle

The pattern is consistent across all frameworks:
1. Introduce `APP_ENV=local` environment variable check
2. Use existing environment variables when possible (e.g., `DATABASE_URL`)
3. Only add conditional logic for services that differ between local/production
4. Preserve production behavior as default

---

### Node.js / TypeScript Applications

#### Database Configuration (PostgreSQL)

**Before (Production-only):**
```typescript
// lib/db.ts
import { Pool } from 'pg';

export const db = new Pool({
  connectionString: process.env.DATABASE_URL,
});
```

**After (Local + Production):**
```typescript
// lib/db.ts
import { Pool } from 'pg';

const isLocal = process.env.APP_ENV === 'local';

export const db = new Pool({
  connectionString: process.env.DATABASE_URL,
  // Local dev doesn't need SSL, production does
  ssl: isLocal ? false : { rejectUnauthorized: false },
});
```

**Explanation:**
- `DATABASE_URL` works in both environments (set by dev container or App Platform)
- Only SSL configuration changes based on environment
- Minimal refactoring needed

---

#### Redis/Valkey Configuration

**Before (Production-only):**
```typescript
// lib/cache.ts
import Redis from 'ioredis';

export const redis = new Redis(process.env.REDIS_URL);
```

**After (Local + Production):**
```typescript
// lib/cache.ts
import Redis from 'ioredis';

// VALKEY_URL is set by dev container (local) or App Platform (production)
export const redis = new Redis(process.env.VALKEY_URL || process.env.REDIS_URL);
```

**Explanation:**
- Dev container sets `VALKEY_URL=redis://valkey:6379`
- App Platform sets `REDIS_URL` (managed Redis/Valkey)
- Fallback pattern handles both

---

#### Object Storage (S3/MinIO)

**Before (AWS S3 only):**
```typescript
// lib/storage.ts
import { S3Client } from '@aws-sdk/client-s3';

export const s3 = new S3Client({
  region: process.env.AWS_REGION,
  credentials: {
    accessKeyId: process.env.AWS_ACCESS_KEY_ID!,
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY!,
  },
});
```

**After (MinIO local, S3/Spaces production):**
```typescript
// lib/storage.ts
import { S3Client } from '@aws-sdk/client-s3';

const isLocal = process.env.APP_ENV === 'local';

export const s3 = new S3Client({
  endpoint: isLocal ? process.env.MINIO_ENDPOINT : process.env.SPACES_ENDPOINT,
  region: isLocal ? 'us-east-1' : process.env.SPACES_REGION,
  credentials: {
    accessKeyId: isLocal
      ? process.env.MINIO_ACCESS_KEY!
      : process.env.SPACES_KEY!,
    secretAccessKey: isLocal
      ? process.env.MINIO_SECRET_KEY!
      : process.env.SPACES_SECRET!,
  },
  forcePathStyle: isLocal, // MinIO requires path-style access
});
```

**Explanation:**
- MinIO mimics S3 API locally
- `forcePathStyle` required for MinIO (not for AWS S3/DO Spaces)
- Different credentials for local vs production

---

#### Next.js Environment Variables

**Create/Update `.env.local` (gitignored):**
```bash
# .env.local (for local development)
APP_ENV=local

# These are automatically set by dev container:
# DATABASE_URL=postgresql://postgres:postgres@postgres:5432/devcontainer_db
# VALKEY_URL=redis://valkey:6379
# MINIO_ENDPOINT=http://minio:9000
# MINIO_ACCESS_KEY=minio
# MINIO_SECRET_KEY=minio12345
```

**Update `next.config.js` to expose environment:**
```javascript
// next.config.js
module.exports = {
  env: {
    APP_ENV: process.env.APP_ENV,
  },
};
```

---

### Python Applications (FastAPI, Django, Flask)

#### Database Configuration (PostgreSQL)

**Before (Production-only):**
```python
# config/database.py
import os
from sqlalchemy import create_engine

DATABASE_URL = os.getenv("DATABASE_URL")
engine = create_engine(DATABASE_URL)
```

**After (Local + Production):**
```python
# config/database.py
import os
from sqlalchemy import create_engine

APP_ENV = os.getenv("APP_ENV", "production")
is_local = APP_ENV == "local"

DATABASE_URL = os.getenv("DATABASE_URL")

# PostgreSQL connection args differ for local vs production
connect_args = {}
if not is_local:
    connect_args["sslmode"] = "require"

engine = create_engine(DATABASE_URL, connect_args=connect_args)
```

---

#### Redis/Valkey Configuration

**Before (Production-only):**
```python
# config/cache.py
import os
import redis

REDIS_URL = os.getenv("REDIS_URL")
redis_client = redis.from_url(REDIS_URL)
```

**After (Local + Production):**
```python
# config/cache.py
import os
import redis

# Dev container sets VALKEY_URL, production sets REDIS_URL
REDIS_URL = os.getenv("VALKEY_URL") or os.getenv("REDIS_URL")
redis_client = redis.from_url(REDIS_URL)
```

---

#### Object Storage (S3/MinIO with boto3)

**Before (AWS S3 only):**
```python
# config/storage.py
import os
import boto3

s3_client = boto3.client(
    's3',
    aws_access_key_id=os.getenv("AWS_ACCESS_KEY_ID"),
    aws_secret_access_key=os.getenv("AWS_SECRET_ACCESS_KEY"),
    region_name=os.getenv("AWS_REGION")
)
```

**After (MinIO local, S3/Spaces production):**
```python
# config/storage.py
import os
import boto3

APP_ENV = os.getenv("APP_ENV", "production")
is_local = APP_ENV == "local"

if is_local:
    # Local: MinIO
    s3_client = boto3.client(
        's3',
        endpoint_url=os.getenv("MINIO_ENDPOINT"),
        aws_access_key_id=os.getenv("MINIO_ACCESS_KEY"),
        aws_secret_access_key=os.getenv("MINIO_SECRET_KEY"),
        region_name='us-east-1',
    )
else:
    # Production: AWS S3 or DigitalOcean Spaces
    s3_client = boto3.client(
        's3',
        endpoint_url=os.getenv("SPACES_ENDPOINT"),  # Optional for DO Spaces
        aws_access_key_id=os.getenv("SPACES_KEY"),
        aws_secret_access_key=os.getenv("SPACES_SECRET"),
        region_name=os.getenv("SPACES_REGION")
    )
```

---

#### FastAPI Example (Full Configuration)

**Before:**
```python
# main.py
from fastapi import FastAPI
import os
from sqlalchemy import create_engine

app = FastAPI()

DATABASE_URL = os.getenv("DATABASE_URL")
engine = create_engine(DATABASE_URL)
```

**After:**
```python
# main.py
from fastapi import FastAPI
import os
from sqlalchemy import create_engine

app = FastAPI()

APP_ENV = os.getenv("APP_ENV", "production")
is_local = APP_ENV == "local"

DATABASE_URL = os.getenv("DATABASE_URL")

# Local dev doesn't need SSL
connect_args = {} if is_local else {"sslmode": "require"}
engine = create_engine(DATABASE_URL, connect_args=connect_args)
```

**Create `.env` file (gitignored):**
```bash
# .env (for local development)
APP_ENV=local

# These are automatically set by dev container:
# DATABASE_URL=postgresql://postgres:postgres@postgres:5432/devcontainer_db
# VALKEY_URL=redis://valkey:6379
```

---

### Go Applications

#### Database Configuration (PostgreSQL)

**Before (Production-only):**
```go
// config/database.go
package config

import (
    "database/sql"
    "os"
    _ "github.com/lib/pq"
)

func NewDB() (*sql.DB, error) {
    return sql.Open("postgres", os.Getenv("DATABASE_URL"))
}
```

**After (Local + Production):**
```go
// config/database.go
package config

import (
    "database/sql"
    "os"
    _ "github.com/lib/pq"
)

func NewDB() (*sql.DB, error) {
    dbURL := os.Getenv("DATABASE_URL")
    isLocal := os.Getenv("APP_ENV") == "local"

    if isLocal {
        // Local: disable SSL
        dbURL += "?sslmode=disable"
    }

    return sql.Open("postgres", dbURL)
}
```

---

#### Redis/Valkey Configuration

**Before (Production-only):**
```go
// config/cache.go
package config

import (
    "os"
    "github.com/go-redis/redis/v8"
)

func NewRedis() *redis.Client {
    opt, _ := redis.ParseURL(os.Getenv("REDIS_URL"))
    return redis.NewClient(opt)
}
```

**After (Local + Production):**
```go
// config/cache.go
package config

import (
    "os"
    "github.com/go-redis/redis/v8"
)

func NewRedis() *redis.Client {
    // Use VALKEY_URL (dev container) or REDIS_URL (production)
    redisURL := os.Getenv("VALKEY_URL")
    if redisURL == "" {
        redisURL = os.Getenv("REDIS_URL")
    }

    opt, _ := redis.ParseURL(redisURL)
    return redis.NewClient(opt)
}
```

---

### Rust Applications

#### Database Configuration (PostgreSQL with sqlx)

**Before (Production-only):**
```rust
// src/config/database.rs
use sqlx::postgres::PgPoolOptions;

pub async fn create_pool() -> Result<sqlx::PgPool, sqlx::Error> {
    let database_url = std::env::var("DATABASE_URL")
        .expect("DATABASE_URL must be set");

    PgPoolOptions::new()
        .max_connections(5)
        .connect(&database_url)
        .await
}
```

**After (Local + Production):**
```rust
// src/config/database.rs
use sqlx::postgres::PgPoolOptions;

pub async fn create_pool() -> Result<sqlx::PgPool, sqlx::Error> {
    let database_url = std::env::var("DATABASE_URL")
        .expect("DATABASE_URL must be set");

    let is_local = std::env::var("APP_ENV")
        .unwrap_or_default() == "local";

    let mut options = PgPoolOptions::new().max_connections(5);

    // Local: SSL not required
    // Production: SSL required for managed databases
    let url = if is_local {
        database_url
    } else {
        format!("{}?sslmode=require", database_url)
    };

    options.connect(&url).await
}
```

---

### Common Refactoring Checklist

When refactoring an existing application, follow this checklist:

- [ ] **Detect all services** used (database, cache, storage, message queue)
- [ ] **Identify configuration files** (config/, lib/, or framework-specific)
- [ ] **Ask permission** before modifying user code
- [ ] **Add `APP_ENV` check** at the top of configuration files
- [ ] **Update database connections** (SSL settings for local vs production)
- [ ] **Update cache connections** (use `VALKEY_URL` or `REDIS_URL`)
- [ ] **Update storage clients** (MinIO local, S3/Spaces production)
- [ ] **Create `.env` or `.env.local`** file with `APP_ENV=local` (add to `.gitignore`)
- [ ] **Test locally** (run test suite or verify connections manually)
- [ ] **Document changes** in PR or commit message

---

### When NOT to Refactor

**Skip refactoring if:**
1. Code already uses environment variables correctly (e.g., `DATABASE_URL`)
2. No hardcoded production URLs or credentials
3. Application is stateless (no database, cache, or storage dependencies)
4. User explicitly says "don't modify my code, just set up the container"

**In these cases:**
- Only configure `.devcontainer/.env`
- Provide connection examples in a separate `LOCAL_DEVELOPMENT.md` file
- Let user handle refactoring at their own pace

---

## Troubleshooting Common Issues

### Issue 1: Container Name Conflicts

**Symptom:** Error: "container name already exists"

**Cause:** Another dev container project is using the same container names

**Solution:**
```bash
# Stop and remove all devcontainer services
docker ps -q --filter "name=devcontainer-" | xargs docker stop
docker ps -aq --filter "name=devcontainer-" | xargs docker rm

# Then user reopens in dev container
```

### Issue 2: Port Already Allocated

**Symptom:** Error: "port 5432 is already allocated"

**Cause:** Another service is using the same port

**Solution:**
```bash
# Check what's using the port (macOS/Linux)
lsof -i :5432

# Stop the conflicting service or change the port in docker-compose.yml
```

### Issue 3: Disk Space Issues

**Symptom:** Build fails with "no space left on device"

**Solution:**
```bash
# Check Docker disk usage
docker system df

# Safe cleanup (remove dangling images, stopped containers)
docker system prune

# Aggressive cleanup (remove all unused images)
docker system prune -a
```

### Issue 4: Credential Mounting Fails (Windows/Linux)

**Symptom:** `doctl`, `gh`, or AI CLI tools not authenticated inside container

**Solution:**
```bash
# Authenticate inside the container (one-time)
doctl auth init
gh auth login
claude auth login
```

### Issue 5: Service Won't Start

**Symptom:** Container starts but service (e.g., Postgres) is not accessible

**Diagnostic Steps:**
```bash
# 1. Check if service container is running
docker ps | grep devcontainer-postgres

# 2. Check service logs
docker logs devcontainer-postgres

# 3. Verify service is in COMPOSE_PROFILES
cat .devcontainer/.env | grep COMPOSE_PROFILES

# 4. Check if port is accessible from app container
docker exec -it devcontainer-app-1 nc -zv postgres 5432
```

---

## Managing Services During Development

### Starting Services After Reboot

When the user restarts their computer, containers do not auto-start. Guide them:

```bash
# User must reopen in dev container via VS Code/Cursor
# Services automatically start when container opens
```

### Stopping Services to Free Resources

```bash
# From project directory (outside container)
docker compose -f .devcontainer/docker-compose.yml down

# Or stop without removing (faster restart)
docker compose -f .devcontainer/docker-compose.yml stop
```

### Restarting a Single Service

```bash
# From project directory
docker compose -f .devcontainer/docker-compose.yml restart postgres

# Or from anywhere
docker restart devcontainer-postgres
```

### Checking Service Status

```bash
# List all devcontainer services
docker ps --filter "name=devcontainer-"

# Check specific service logs
docker logs devcontainer-postgres
docker logs devcontainer-valkey
docker logs devcontainer-minio
```

---

## Service-Specific Operations

### PostgreSQL

**Connection from app container:**
```bash
psql postgresql://postgres:postgres@postgres:5432/devcontainer_db
```

**Connection from host:**
```bash
psql postgresql://postgres:postgres@localhost:5432/devcontainer_db
```

**Environment variable (automatically set):**
```bash
DATABASE_URL=postgresql://postgres:postgres@postgres:5432/devcontainer_db
```

### Valkey/Redis

**Connection from app container:**
```bash
redis-cli -h valkey -p 6379
```

**Environment variable (automatically set):**
```bash
VALKEY_URL=redis://valkey:6379
```

### MinIO (S3-Compatible Storage)

**Access from app container:**
- Endpoint: `http://minio:9000`
- Access Key: `minio`
- Secret Key: `minio12345`

**Access from host:**
- Console: `http://localhost:8900` (credentials: `minio`/`minio12345`)
- API: `http://localhost:9000`

**Environment variables (automatically set):**
```bash
MINIO_ENDPOINT=http://minio:9000
MINIO_ACCESS_KEY=minio
MINIO_SECRET_KEY=minio12345
```

### MySQL

**Connection from app container:**
```bash
mysql -h mysql -u mysql -p devcontainer_db
# Password: mysql
```

**Environment variable (automatically set):**
```bash
MYSQL_URL=mysql://mysql:mysql@mysql:3306/devcontainer_db
```

### MongoDB

**Connection from app container:**
```bash
mongosh "mongodb://mongodb:mongodb@mongodb:27017/devcontainer_db"
```

**Environment variable (automatically set):**
```bash
MONGODB_URL=mongodb://mongodb:mongodb@mongodb:27017/devcontainer_db
```

### Kafka

**Broker from app container:**
- Bootstrap servers: `kafka:9092`

**Environment variable (automatically set):**
```bash
KAFKA_BROKERS=kafka:9092
```

### OpenSearch

**Access from app container:**
- Endpoint: `http://opensearch:9200`
- Credentials: `admin`/`AdminPassword123!`

**Access from host:**
- Dashboards: `http://localhost:5601`

**Environment variable (automatically set):**
```bash
OPENSEARCH_URL=http://opensearch:9200
```

---

## Modifying Configuration After Initial Setup

If the user needs to change services or runtimes after setup:

1. **Edit `.devcontainer/.env`** with new configuration
2. **Instruct user to rebuild container:**
   - Press `Cmd/Ctrl + Shift + P`
   - Select "Dev Containers: Rebuild Container"
3. **Wait for rebuild** (5-10 minutes)

**Example: Adding Valkey to existing setup**
```bash
# Edit .devcontainer/.env
# Change: COMPOSE_PROFILES=
# To:     COMPOSE_PROFILES=valkey

# Then user rebuilds container via VS Code/Cursor
```

---

## Best Practices for AI Assistants

1. **Always ask before modifying `.env`** - Explain what you're changing and why
2. **Check system resources** - Don't enable all services on low-RAM systems
3. **Explain the handoff** - Be clear when user needs to take UI action
4. **Don't run docker compose up during setup** - Let dev container handle this
5. **Test suite is optional** - Only run when explicitly requested or troubleshooting
6. **Commit configuration changes** - Help user track dev container setup in git
7. **Provide connection examples** - Show how to connect to services in their language

---

## Quick Reference: AI Decision Tree

```
User wants dev container setup
  ↓
Ask about languages & services
  ↓
Check RAM constraints
  ↓
Modify .devcontainer/.env
  ↓
Explain configuration
  ↓
Instruct user to "Reopen in Container"
  ↓
[User opens in dev container]
  ↓
User returns with issue?
  ├─ Yes → Run test suite → Diagnose
  └─ No → Help with application code
```

---

## Files to Read for Context

When assisting users, read these files for context:

- `.devcontainer/.env` - Current service and runtime configuration
- `.devcontainer/docker-compose.yml` - Service definitions and ports
- `.devcontainer/devcontainer.json` - Dev container settings
- `CLAUDE.md` - Project-specific context and architecture
- `.devcontainer/README.md` - Human-readable documentation

---

## Summary: What AI Can and Cannot Do

### ✅ AI CAN Do
- Read user requirements
- Modify `.devcontainer/.env` configuration
- Explain what was configured and why
- Provide clear setup instructions
- Run test suite after container is running
- Troubleshoot service connectivity issues
- Show how to connect to services
- Manage Docker containers via CLI

### ❌ AI CANNOT Do
- Open dev container (UI action - user must do this)
- Click buttons in VS Code/Cursor
- Install Docker Desktop
- Automatically rebuild containers (user must trigger via UI)

### 🤝 Handoff Points
1. After configuration → User opens in dev container
2. After rebuild instruction → User triggers rebuild
3. When Docker not installed → User installs Docker Desktop

---

**Last Updated:** 2025-11-12
