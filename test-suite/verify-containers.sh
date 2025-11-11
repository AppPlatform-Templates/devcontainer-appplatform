#!/bin/bash
# Verification script for DevContainer Docker Compose services
# Usage: ./verify-containers.sh

set -e

COMPOSE_FILE=".devcontainer/docker-compose.yml"
COMPOSE_CMD="docker compose -f $COMPOSE_FILE"

echo "=========================================="
echo "DevContainer Service Verification"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check service status
check_service() {
    local service=$1
    local port=$2
    local health_check=$3
    
    echo -n "Checking $service... "
    
    # Check if container is running
    if $COMPOSE_CMD ps $service | grep -q "Up"; then
        echo -e "${GREEN}✓ Running${NC}"
        
        # Check port if provided
        if [ -n "$port" ]; then
            if nc -z localhost $port 2>/dev/null || timeout 1 bash -c "echo > /dev/tcp/localhost/$port" 2>/dev/null; then
                echo -e "  Port $port: ${GREEN}✓ Accessible${NC}"
            else
                echo -e "  Port $port: ${YELLOW}⚠ Not accessible (may be starting)${NC}"
            fi
        fi
        
        # Run health check if provided
        if [ -n "$health_check" ]; then
            if eval "$health_check" > /dev/null 2>&1; then
                echo -e "  Health check: ${GREEN}✓ Passed${NC}"
            else
                echo -e "  Health check: ${YELLOW}⚠ Failed or not ready${NC}"
            fi
        fi
        
        return 0
    else
        echo -e "${RED}✗ Not running${NC}"
        return 1
    fi
}

# 1. Check all running containers
echo "1. Container Status:"
echo "-------------------"
$COMPOSE_CMD ps
echo ""

# 2. Check individual services
echo "2. Service Health Checks:"
echo "------------------------"

# PostgreSQL
check_service "postgres" "5432" "psql -h localhost -U postgres -d devcontainer_db -c 'SELECT 1' > /dev/null 2>&1"

# MinIO
check_service "minio" "9000"
check_service "minio" "8900"

# App container
check_service "app" ""

# Optional services (if enabled)
if $COMPOSE_CMD ps valkey 2>/dev/null | grep -q "Up"; then
    check_service "valkey" "6379" "redis-cli -h localhost -p 6379 ping > /dev/null 2>&1 || valkey-cli -h localhost -p 6379 ping > /dev/null 2>&1"
fi

if $COMPOSE_CMD ps mysql 2>/dev/null | grep -q "Up"; then
    check_service "mysql" "3306" "mysql -h localhost -u mysql -pmysql -e 'SELECT 1' > /dev/null 2>&1"
fi

if $COMPOSE_CMD ps mongodb 2>/dev/null | grep -q "Up"; then
    check_service "mongodb" "27017" "mongosh --quiet --eval 'db.adminCommand(\"ping\")' > /dev/null 2>&1"
fi

if $COMPOSE_CMD ps kafka 2>/dev/null | grep -q "Up"; then
    check_service "kafka" "9092"
fi

if $COMPOSE_CMD ps opensearch 2>/dev/null | grep -q "Up"; then
    check_service "opensearch" "9200" "curl -s http://localhost:9200/_cluster/health > /dev/null 2>&1"
fi

echo ""
echo "3. Recent Logs (last 10 lines per service):"
echo "-------------------------------------------"
for service in $($COMPOSE_CMD ps --services); do
    if $COMPOSE_CMD ps $service | grep -q "Up"; then
        echo ""
        echo "--- $service logs ---"
        $COMPOSE_CMD logs --tail=10 $service 2>/dev/null || echo "No logs available"
    fi
done

echo ""
echo "4. Network Connectivity (from app container):"
echo "---------------------------------------------"
echo "Checking if app container can communicate with services..."

# Function to test connectivity from app container
test_app_connectivity() {
    local service=$1
    local test_cmd=$2
    local description=$3
    
    if $COMPOSE_CMD exec -T app bash -c "$test_cmd" > /dev/null 2>&1; then
        echo -e "app → $service ($description): ${GREEN}✓ Connected${NC}"
        return 0
    else
        echo -e "app → $service ($description): ${RED}✗ Not connected${NC}"
        return 1
    fi
}

# Test PostgreSQL (already tested)
if $COMPOSE_CMD ps postgres 2>/dev/null | grep -q "Up"; then
    test_app_connectivity "postgres" "timeout 2 bash -c 'echo > /dev/tcp/postgres/5432' 2>/dev/null" "port 5432"
    test_app_connectivity "postgres" "PGPASSWORD=postgres psql -h postgres -U postgres -d devcontainer_db -c 'SELECT 1'" "database query"
fi

# Test MinIO (already tested)
if $COMPOSE_CMD ps minio 2>/dev/null | grep -q "Up"; then
    test_app_connectivity "minio" "timeout 2 bash -c 'echo > /dev/tcp/minio/9000' 2>/dev/null" "port 9000"
    test_app_connectivity "minio" "curl -s -f http://minio:9000/minio/health/live" "health endpoint"
fi

# Test Valkey
if $COMPOSE_CMD ps valkey 2>/dev/null | grep -q "Up"; then
    test_app_connectivity "valkey" "timeout 2 bash -c 'echo > /dev/tcp/valkey/6379' 2>/dev/null" "port 6379"
    test_app_connectivity "valkey" "valkey-cli -h valkey -p 6379 ping 2>/dev/null || redis-cli -h valkey -p 6379 ping 2>/dev/null" "redis ping"
fi

# Test MySQL
if $COMPOSE_CMD ps mysql 2>/dev/null | grep -q "Up"; then
    test_app_connectivity "mysql" "timeout 2 bash -c 'echo > /dev/tcp/mysql/3306' 2>/dev/null" "port 3306"
    test_app_connectivity "mysql" "mysql -h mysql -u mysql -pmysql -e 'SELECT 1' 2>/dev/null" "database query"
fi

# Test MongoDB
if $COMPOSE_CMD ps mongodb 2>/dev/null | grep -q "Up"; then
    test_app_connectivity "mongodb" "timeout 2 bash -c 'echo > /dev/tcp/mongodb/27017' 2>/dev/null" "port 27017"
    test_app_connectivity "mongodb" "mongosh --quiet mongodb://mongodb:mongodb@mongodb:27017/admin --eval 'db.adminCommand(\"ping\")' 2>/dev/null" "database ping"
fi

# Test Kafka
if $COMPOSE_CMD ps kafka 2>/dev/null | grep -q "Up"; then
    test_app_connectivity "kafka" "timeout 2 bash -c 'echo > /dev/tcp/kafka/29092' 2>/dev/null" "port 29092"
    # Test Kafka connectivity using kcat/kafkacat or netcat
    if $COMPOSE_CMD exec -T app bash -c "which kcat > /dev/null 2>&1 || which kafkacat > /dev/null 2>&1" 2>/dev/null; then
        KAFKA_CMD="kcat -b kafka:29092 -L 2>/dev/null || kafkacat -b kafka:29092 -L 2>/dev/null"
        test_app_connectivity "kafka" "$KAFKA_CMD" "broker list"
    else
        # Fallback: test port connectivity
        test_app_connectivity "kafka" "timeout 2 bash -c 'echo > /dev/tcp/kafka/9092' 2>/dev/null" "port 9092"
    fi
fi

# Test OpenSearch
if $COMPOSE_CMD ps opensearch 2>/dev/null | grep -q "Up"; then
    test_app_connectivity "opensearch" "timeout 2 bash -c 'echo > /dev/tcp/opensearch/9200' 2>/dev/null" "port 9200"
    test_app_connectivity "opensearch" "curl -s -f http://opensearch:9200/_cluster/health" "cluster health"
fi

echo ""
echo "5. Resource Usage:"
echo "-----------------"
$COMPOSE_CMD stats --no-stream

echo ""
echo "=========================================="
echo "Verification Complete"
echo "=========================================="

