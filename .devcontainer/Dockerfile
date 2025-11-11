# =============================================================================
# DigitalOcean App Platform Development Container
# =============================================================================
# Base image with Ubuntu 24.04
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# =============================================================================
# Load version specifications from .env
# =============================================================================
ARG INSTALL_NODE=true
ARG NVM_VERSION=0.40.3
ARG NODE_VERSIONS="24 22"
ARG NODE_DEFAULT_VERSION=24

ARG INSTALL_PYTHON=true
ARG PYTHON_VERSIONS="3.12 3.13"
ARG PYTHON_DEFAULT_VERSION=3.13

ARG INSTALL_GOLANG=true
ARG GOLANG_VERSION=1.23.4

ARG INSTALL_RUST=true

ARG MONGOSH_VERSION=8.0

# =============================================================================
# Install base system dependencies
# =============================================================================
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    git \
    unzip \
    jq \
    less \
    procps \
    build-essential \
    netcat-openbsd \
    iputils-ping \
    wget \
    software-properties-common \
    sudo \
    pkg-config \
    libssl-dev \
    cmake \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# =============================================================================
# Install Node.js via NVM (if enabled)
# =============================================================================
RUN if [ "$INSTALL_NODE" = "true" ]; then \
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_VERSION}/install.sh | bash \
        && export NVM_DIR="/root/.nvm" \
        && . "$NVM_DIR/nvm.sh" \
        && for version in $NODE_VERSIONS; do \
            nvm install $version; \
        done \
        && nvm alias default ${NODE_DEFAULT_VERSION} \
        && nvm use default; \
    fi

# Set Node environment variables globally
ENV NVM_DIR=/root/.nvm
ENV PATH=$NVM_DIR/versions/node/v${NODE_DEFAULT_VERSION}.0/bin:$PATH

# =============================================================================
# Install Python via UV (if enabled)
# =============================================================================
RUN if [ "$INSTALL_PYTHON" = "true" ]; then \
        curl -LsSf https://astral.sh/uv/install.sh | sh \
        && export PATH="/root/.local/bin:$PATH" \
        && for version in $PYTHON_VERSIONS; do \
            uv python install $version; \
        done \
        && uv python pin $PYTHON_DEFAULT_VERSION; \
    fi

# Set UV and Python environment variables
ENV PATH=/root/.local/bin:$PATH

# =============================================================================
# Install Golang (if enabled)
# =============================================================================
RUN if [ "$INSTALL_GOLANG" = "true" ]; then \
        arch="$(uname -m)"; \
        case "$arch" in \
            x86_64) GO_ARCH="amd64" ;; \
            aarch64|arm64) GO_ARCH="arm64" ;; \
            *) GO_ARCH="amd64" ;; \
        esac && \
        wget -q "https://go.dev/dl/go${GOLANG_VERSION}.linux-${GO_ARCH}.tar.gz" -O /tmp/go.tar.gz \
        && rm -rf /usr/local/go \
        && tar -C /usr/local -xzf /tmp/go.tar.gz \
        && rm /tmp/go.tar.gz; \
    fi

# Set Go environment variables
ENV PATH=/usr/local/go/bin:$PATH
ENV GOPATH=/go
ENV PATH=$GOPATH/bin:$PATH

# =============================================================================
# Install Rust via rustup (if enabled)
# =============================================================================
RUN if [ "$INSTALL_RUST" = "true" ]; then \
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y \
        && . "$HOME/.cargo/env"; \
    fi

# Set Rust environment variables
ENV PATH=/root/.cargo/bin:$PATH

# =============================================================================
# Install CLI Tools - always latest
# =============================================================================
# DigitalOcean CLI (doctl)
RUN arch="$(uname -m)"; \
    case "$arch" in \
        x86_64) DOCTL_ARCH="linux-amd64" ;; \
        aarch64|arm64) DOCTL_ARCH="linux-arm64" ;; \
        *) DOCTL_ARCH="linux-amd64" ;; \
    esac && \
    tmpdir="$(mktemp -d)" && \
    DOCTL_VERSION=$(curl -s https://api.github.com/repos/digitalocean/doctl/releases/latest | jq -r .tag_name) && \
    curl -fsSL "https://github.com/digitalocean/doctl/releases/download/${DOCTL_VERSION}/doctl-${DOCTL_VERSION#v}-${DOCTL_ARCH}.tar.gz" \
        | tar -xz -C "$tmpdir" && \
    install -m 0755 "$tmpdir/doctl" /usr/local/bin/doctl && \
    rm -rf "$tmpdir"

# GitHub CLI (gh)
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update \
    && apt-get install -y gh \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# =============================================================================
# Install Database Clients
# =============================================================================
RUN apt-get update && apt-get install -y --no-install-recommends \
    postgresql-client \
    mysql-client \
    valkey \
    valkey-redis-compat \
    kcat \
    gnupg \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install MongoDB shell (mongosh)
RUN curl -fsSL "https://www.mongodb.org/static/pgp/server-${MONGOSH_VERSION}.asc" | gpg -o "/usr/share/keyrings/mongodb-server-${MONGOSH_VERSION}.gpg" --dearmor \
    && echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-${MONGOSH_VERSION}.gpg ] https://repo.mongodb.org/apt/ubuntu noble/mongodb-org/${MONGOSH_VERSION} multiverse" | tee /etc/apt/sources.list.d/mongodb-org-${MONGOSH_VERSION}.list \
    && apt-get update \
    && apt-get install -y mongodb-mongosh \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# =============================================================================
# Create devcontainer user and set up environment
# =============================================================================
RUN useradd -ms /bin/bash devcontainer \
    && echo "devcontainer ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Copy runtime configurations to devcontainer user
RUN if [ "$INSTALL_NODE" = "true" ]; then \
        cp -r /root/.nvm /home/devcontainer/.nvm \
        && chown -R devcontainer:devcontainer /home/devcontainer/.nvm; \
    fi

RUN if [ "$INSTALL_PYTHON" = "true" ]; then \
        cp -r /root/.local /home/devcontainer/.local \
        && chown -R devcontainer:devcontainer /home/devcontainer/.local; \
    fi

RUN if [ "$INSTALL_RUST" = "true" ]; then \
        cp -r /root/.cargo /home/devcontainer/.cargo \
        && cp -r /root/.rustup /home/devcontainer/.rustup \
        && chown -R devcontainer:devcontainer /home/devcontainer/.cargo /home/devcontainer/.rustup; \
    fi

# Switch to devcontainer user
USER devcontainer
WORKDIR /workspaces/app

# =============================================================================
# Set up shell environment for devcontainer user
# =============================================================================
# Node.js (NVM)
RUN if [ "$INSTALL_NODE" = "true" ]; then \
        echo 'export NVM_DIR="$HOME/.nvm"' >> /home/devcontainer/.bashrc \
        && echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> /home/devcontainer/.bashrc \
        && echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >> /home/devcontainer/.bashrc; \
    fi

# Python (UV)
RUN if [ "$INSTALL_PYTHON" = "true" ]; then \
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> /home/devcontainer/.bashrc \
        && echo 'eval "$(uv generate-shell-completion bash)"' >> /home/devcontainer/.bashrc; \
    fi

# Golang
RUN if [ "$INSTALL_GOLANG" = "true" ]; then \
        echo 'export PATH="/usr/local/go/bin:$PATH"' >> /home/devcontainer/.bashrc \
        && echo 'export GOPATH="$HOME/go"' >> /home/devcontainer/.bashrc \
        && echo 'export PATH="$GOPATH/bin:$PATH"' >> /home/devcontainer/.bashrc; \
    fi

# Rust
RUN if [ "$INSTALL_RUST" = "true" ]; then \
        echo 'source "$HOME/.cargo/env"' >> /home/devcontainer/.bashrc; \
    fi

# doctl completion
RUN echo 'source <(doctl completion bash)' >> /home/devcontainer/.bashrc

# Update devcontainer user's environment variables
ENV NVM_DIR=/home/devcontainer/.nvm
ENV PATH=/home/devcontainer/.local/bin:/usr/local/go/bin:/home/devcontainer/.cargo/bin:$NVM_DIR/versions/node/v${NODE_DEFAULT_VERSION}.0/bin:$PATH

# Keep container running
CMD ["sleep", "infinity"]
