#!/bin/bash
# Setup script to start DevContainer Docker Compose services
# Usage: ./setup-containers.sh [profile1] [profile2] ...
# If no arguments, reads COMPOSE_PROFILES from .env file

set -e

if ! command -v docker >/dev/null 2>&1; then
    echo "docker CLI not found in PATH. Assuming services are already running."
    exit 0
fi

COMPOSE_FILE=".devcontainer/docker-compose.yml"
COMPOSE_CMD="docker compose -f $COMPOSE_FILE"

echo "=========================================="
echo "DevContainer Service Setup"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Load .env file to get COMPOSE_PROFILES
if [ -f ".devcontainer/.env" ]; then
    echo -e "${BLUE}Loading environment variables from .devcontainer/.env${NC}"
    set -a
    source .devcontainer/.env
    set +a
fi

# Determine which profiles to use
if [ $# -gt 0 ]; then
    # Use command line arguments
    PROFILES=""
    for profile in "$@"; do
        PROFILES="$PROFILES --profile $profile"
    done
    echo -e "${BLUE}Starting services with profiles: $@${NC}"
elif [ -n "$COMPOSE_PROFILES" ]; then
    # Use COMPOSE_PROFILES from .env
    echo -e "${BLUE}Starting services with profiles from .env: $COMPOSE_PROFILES${NC}"
    PROFILES=""
    IFS=',' read -ra PROFILE_ARRAY <<< "$COMPOSE_PROFILES"
    for profile in "${PROFILE_ARRAY[@]}"; do
        profile=$(echo "$profile" | xargs)  # trim whitespace
        if [ -n "$profile" ]; then
            PROFILES="$PROFILES --profile $profile"
        fi
    done
else
    echo -e "${BLUE}No profiles specified. Starting default services only (postgres, minio, app)${NC}"
    PROFILES=""
fi

# Start services
echo ""
echo -e "${BLUE}1. Starting services...${NC}"
if [ -n "$PROFILES" ]; then
    $COMPOSE_CMD $PROFILES up -d
else
    $COMPOSE_CMD up -d
fi

# Wait for services to be ready
echo ""
echo -e "${YELLOW}Waiting for services to be ready...${NC}"
sleep 10

# Show status
echo ""
echo -e "${BLUE}2. Service Status:${NC}"
$COMPOSE_CMD ps

echo ""
echo -e "${GREEN}=========================================="
echo "Setup Complete!"
echo "==========================================${NC}"
echo ""
echo "Services started based on COMPOSE_PROFILES in .env"
echo "Run './verify-containers.sh' to verify connectivity."
echo ""
echo "Default services (always running):"
echo "  - PostgreSQL: localhost:5432"
echo "  - MinIO API: localhost:9000, Console: localhost:8900"
echo ""
if [ -n "$COMPOSE_PROFILES" ]; then
    echo "Additional services (from COMPOSE_PROFILES=$COMPOSE_PROFILES):"
    [[ "$COMPOSE_PROFILES" == *"valkey"* ]] && echo "  - Valkey: localhost:6379"
    [[ "$COMPOSE_PROFILES" == *"mysql"* ]] && echo "  - MySQL: localhost:3306"
    [[ "$COMPOSE_PROFILES" == *"mongodb"* ]] && echo "  - MongoDB: localhost:27017"
    [[ "$COMPOSE_PROFILES" == *"kafka"* ]] && echo "  - Kafka: localhost:9092"
    [[ "$COMPOSE_PROFILES" == *"opensearch"* ]] && echo "  - OpenSearch: localhost:9200, Dashboards: localhost:5601"
fi

