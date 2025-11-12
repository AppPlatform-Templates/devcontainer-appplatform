#!/usr/bin/env bash
# Post-create script for DevContainer setup
# Installs AI CLI tools and configures doctl

set -euo pipefail

echo "=========================================="
echo "DevContainer Post-Create Setup"
echo "=========================================="
echo ""

# Update npm to latest version first
echo "Updating npm to latest version..."
npm install -g npm@latest

# Install AI CLI tools via npm (requires Node.js from NVM)
echo "Installing AI CLI tools..."
npm install -g @anthropic-ai/claude-code
npm install -g @google/gemini-cli
npm install -g @openai/codex

# Copy Gemini config if it exists
if [ -f "$HOME/.gemini/tokens.json" ] || [ -d "/tmp/gemini-config" ]; then
    mkdir -p "$HOME/.gemini"

    # Try to find and copy from mounted location
    if [ -d "/tmp/gemini-config" ]; then
        cp -r /tmp/gemini-config/* "$HOME/.gemini/" 2>/dev/null || true
    fi

    # Set proper permissions
    chmod 600 "$HOME/.gemini"/* 2>/dev/null || true
fi

# Copy Claude credentials if they exist in mounted volume
# This ensures proper file permissions and authentication persistence
if [ -d "$HOME/.claude" ]; then
    # Copy credentials file if it exists
    if [ -f "$HOME/.claude/.credentials.json" ]; then
        chmod 600 "$HOME/.claude/.credentials.json" 2>/dev/null || true
    fi

    # Copy settings file if it exists
    if [ -f "$HOME/.claude/settings.json" ]; then
        chmod 600 "$HOME/.claude/settings.json" 2>/dev/null || true
    fi

    # Copy .claude.json for bypass permissions mode if it exists
    if [ -f "$HOME/.claude/.claude.json" ]; then
        chmod 600 "$HOME/.claude/.claude.json" 2>/dev/null || true
    fi
fi

# Copy Codex config if it exists
if [ -d "$HOME/.codex" ]; then
    # Set proper permissions on config directory
    chmod 700 "$HOME/.codex" 2>/dev/null || true
    # Set permissions for files (not directories)
    find "$HOME/.codex" -type f -exec chmod 600 {} \; 2>/dev/null || true
    # Set permissions for subdirectories
    find "$HOME/.codex" -type d -exec chmod 700 {} \; 2>/dev/null || true
fi

# Run doctl configuration setup
echo "Setting up doctl configuration..."
bash .devcontainer/setup-doctl-config.sh

echo ""
echo "=========================================="
echo "DevContainer Ready!"
echo "=========================================="
echo ""
echo "Installed tool versions:"
echo ""

# Runtime versions
if command -v node &> /dev/null; then
    echo "  Node.js: $(node --version) (default, via NVM)"
    if [ -d "$HOME/.nvm/versions/node" ]; then
        echo "  Available Node versions: $(ls $HOME/.nvm/versions/node | sed 's/v//g' | tr '\n' ' ')"
    fi
    echo "  npm: $(npm --version)"
fi

if command -v python &> /dev/null; then
    echo "  Python: $(python --version 2>&1 | head -n 1) (default, via UV)"
    if command -v uv &> /dev/null; then
        # Show installed Python versions
        installed_pythons=$(uv python list --only-installed 2>/dev/null | awk '{print $2}' | tr '\n' ' ' || echo '')
        if [ -n "$installed_pythons" ]; then
            echo "  Available Python versions: $installed_pythons"
        fi
    fi
    echo "  UV: $(uv --version)"
fi

if command -v go &> /dev/null; then
    echo "  Go: $(go version | awk '{print $3}')"
fi

if command -v rustc &> /dev/null; then
    echo "  Rust: $(rustc --version)"
    echo "  Cargo: $(cargo --version)"
fi

echo ""
echo "CLI Tools:"
echo "  doctl: $(doctl version)"
echo "  GitHub CLI: $(gh --version | head -n 1)"

echo ""
echo "Database Clients:"
if command -v psql &> /dev/null; then
    echo "  PostgreSQL: $(psql --version)"
fi
if command -v mysql &> /dev/null; then
    echo "  MySQL: $(mysql --version | head -n 1)"
fi
if command -v mongosh &> /dev/null; then
    echo "  MongoDB Shell: $(mongosh --version | head -n 1)"
fi

echo ""
echo "=========================================="
echo "Service Management"
echo "=========================================="
echo ""
echo "Default services (always running):"
echo "  - PostgreSQL (port 5432)"
echo "  - MinIO (ports 9000, 8900)"
echo ""
echo "To enable additional services:"
echo "  1. Edit .devcontainer/.env"
echo "  2. Add profile names to COMPOSE_PROFILES (comma-separated)"
echo "  3. Rebuild the container"
echo ""
echo "Available profiles:"
echo "  - valkey     (Valkey/Redis cache - port 6379)"
echo "  - mysql      (MySQL database - port 3306)"
echo "  - kafka      (Kafka + Zookeeper - port 9092)"
echo "  - opensearch (OpenSearch + Dashboards - ports 9200, 5601)"
echo "  - mongodb    (MongoDB - port 27017)"
echo ""
echo "Example: COMPOSE_PROFILES=valkey,mysql"
echo ""
echo "NOTE: COMPOSE_PROFILES is a native Docker Compose environment variable."
echo "Docker Compose reads it automatically from .env (via env_file config)."
echo ""
echo "To customize runtime versions, also edit .devcontainer/.env"
echo "Then rebuild the container for changes to take effect."
echo ""
