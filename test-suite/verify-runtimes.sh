#!/bin/bash
# Runtime Verification Script for Dev Container
# Tests all installed runtime versions and package managers
# Usage: ./verify-runtimes.sh

set -e

COMPOSE_FILE=".devcontainer/docker-compose.yml"
COMPOSE_CMD="docker compose -f $COMPOSE_FILE"

echo "=========================================="
echo "Runtime & Package Manager Verification"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Track failures
FAILURES=0
TESTS=0

# Function to run command either via docker compose (when available) or directly
if command -v docker >/dev/null 2>&1 && [ -f "$COMPOSE_FILE" ]; then
    run_in_app() {
        $COMPOSE_CMD exec -T app bash -c "$1" 2>&1
    }
else
    run_in_app() {
        bash -lc "$1" 2>&1
    }
fi

# Helper to ensure nvm is available inside non-interactive shells
NVM_INIT='export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"; if [ -s "$NVM_DIR/nvm.sh" ]; then . "$NVM_DIR/nvm.sh"; else echo "nvm not available at $NVM_DIR" >&2; exit 1; fi'

# Ensure uv-managed Python versions (e.g., 3.13) are on PATH even if not globally installed
maybe_add_uv_python_bin() {
    local version=$1
    local uv_dir="$HOME/.local/share/uv/python"

    [ -d "$uv_dir" ] || return

    for candidate in "$uv_dir"/cpython-"$version"*; do
        if [ -d "$candidate/bin" ]; then
            PATH="$candidate/bin:$PATH"
            export PATH
            return
        fi
    done
}

maybe_add_uv_python_bin "3.13"
maybe_add_uv_python_bin "3.12"

# Test function with status reporting
test_runtime() {
    local test_name=$1
    local test_cmd=$2
    local expected_pattern=$3

    TESTS=$((TESTS + 1))
    echo -n "  Testing $test_name... "

    if output=$(run_in_app "$test_cmd" 2>&1); then
        if [ -n "$expected_pattern" ]; then
            if echo "$output" | grep -q "$expected_pattern"; then
                echo -e "${GREEN}✓ PASS${NC}"
                return 0
            else
                echo -e "${RED}✗ FAIL${NC} (unexpected output: $output)"
                FAILURES=$((FAILURES + 1))
                return 1
            fi
        else
            echo -e "${GREEN}✓ PASS${NC}"
            return 0
        fi
    else
        echo -e "${RED}✗ FAIL${NC}"
        echo "  Error: $output"
        FAILURES=$((FAILURES + 1))
        return 1
    fi
}

# =============================================================================
# Node.js Runtime Tests
# =============================================================================
echo -e "${BLUE}1. Node.js Runtime:${NC}"
echo "-------------------"

# Test Node.js versions (24, 22)
test_runtime "Node v24 availability" "bash -lc '$NVM_INIT && nvm use 24 > /dev/null && node --version'" "v24"
test_runtime "Node v22 availability" "bash -lc '$NVM_INIT && nvm use 22 > /dev/null && node --version'" "v22"
test_runtime "Node v24 execution" "bash -lc '$NVM_INIT && nvm use 24 > /dev/null && node -e \"console.log(1+1)\"'" "^2$"

# Test npm package manager
echo -n "  Testing npm (install/uninstall cowsay)... "
if run_in_app "bash -lc '$NVM_INIT && nvm use 24 > /dev/null && npm install -g cowsay > /dev/null 2>&1 && cowsay test > /dev/null 2>&1 && npm uninstall -g cowsay > /dev/null 2>&1'" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ PASS${NC}"
else
    echo -e "${RED}✗ FAIL${NC}"
    FAILURES=$((FAILURES + 1))
fi
TESTS=$((TESTS + 1))

echo ""

# =============================================================================
# Python Runtime Tests
# =============================================================================
echo -e "${BLUE}2. Python Runtime:${NC}"
echo "------------------"

# Test Python versions (3.12, 3.13)
test_runtime "Python 3.13 availability" "bash -lc 'python3.13 --version'" "Python 3.13"
test_runtime "Python 3.12 availability" "bash -lc 'python3.12 --version'" "Python 3.12"
test_runtime "Python 3.13 execution" "bash -lc 'python3.13 -c \"print(1+1)\"'" "^2$"

# Test uv package/venv manager
echo -n "  Testing uv (init/venv)... "
if run_in_app "bash -lc 'tmpdir=$(mktemp -d) && (
    cd \"$tmpdir\" &&
    UV_NON_INTERACTIVE=1 uv init . > /dev/null 2>&1 &&
    uv venv --python 3.13 > /dev/null 2>&1 &&
    .venv/bin/python --version > /dev/null 2>&1
  ); status=$?; rm -rf \"$tmpdir\"; exit $status
' " > /dev/null 2>&1; then
    echo -e "${GREEN}✓ PASS${NC}"
else
    echo -e "${RED}✗ FAIL${NC}"
    FAILURES=$((FAILURES + 1))
fi
TESTS=$((TESTS + 1))

echo ""

# =============================================================================
# Go Runtime Tests
# =============================================================================
echo -e "${BLUE}3. Go Runtime:${NC}"
echo "--------------"

# Test Go version
test_runtime "Go availability" "bash -lc 'go version'" "go1.23"
test_runtime "Go execution" "bash -lc 'echo \"package main; import \\\"fmt\\\"; func main() { fmt.Println(1+1) }\" > /tmp/test.go && go run /tmp/test.go && rm /tmp/test.go'" "^2$"

# Test go install (package manager)
echo -n "  Testing go install (local module)... "
if run_in_app "bash -lc 'tmpdir=$(mktemp -d) && (
    cd \"$tmpdir\" &&
    cat <<\"EOF\" > main.go
package main

import \"fmt\"

func main() {
    fmt.Println(\"runtime ok\")
}
EOF
    cat <<\"EOF\" > go.mod
module runtime/check

go 1.23
EOF
    GOBIN=\"$tmpdir/bin\" go install . > /dev/null 2>&1 &&
    test -x \"$tmpdir/bin/runtime-check\"
  ); status=$?; rm -rf \"$tmpdir\"; exit $status
' " > /dev/null 2>&1; then
    echo -e "${GREEN}✓ PASS${NC}"
else
    echo -e "${RED}✗ FAIL${NC}"
    FAILURES=$((FAILURES + 1))
fi
TESTS=$((TESTS + 1))

echo ""

# =============================================================================
# Rust Runtime Tests
# =============================================================================
echo -e "${BLUE}4. Rust Runtime:${NC}"
echo "---------------"

# Test Rust version
test_runtime "Rust availability" "bash -lc 'rustc --version'" "rustc"
test_runtime "Cargo availability" "bash -lc 'cargo --version'" "cargo"
test_runtime "Rust execution" "bash -lc 'echo \"fn main() { println!(\\\"2\\\"); }\" > /tmp/test.rs && rustc /tmp/test.rs -o /tmp/test && /tmp/test && rm /tmp/test.rs /tmp/test'" "^2$"

# Test cargo (package manager)
echo -n "  Testing cargo (check installed packages)... "
if run_in_app "bash -lc 'cargo --list | grep -q build'" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ PASS${NC}"
else
    echo -e "${RED}✗ FAIL${NC}"
    FAILURES=$((FAILURES + 1))
fi
TESTS=$((TESTS + 1))

echo ""

# =============================================================================
# Summary
# =============================================================================
echo "=========================================="
echo "Runtime Verification Summary"
echo "=========================================="
echo "Total tests: $TESTS"
echo -e "Passed: ${GREEN}$((TESTS - FAILURES))${NC}"
echo -e "Failed: ${RED}$FAILURES${NC}"
echo ""

if [ $FAILURES -eq 0 ]; then
    echo -e "${GREEN}✓ All runtime tests passed!${NC}"
    exit 0
else
    echo -e "${RED}✗ Some runtime tests failed${NC}"
    exit 1
fi
