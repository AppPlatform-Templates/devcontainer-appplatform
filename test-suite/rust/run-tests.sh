#!/bin/bash
# Rust test runner script
# Usage: ./run-tests.sh

set -e

ensure_cmake() {
    if command -v cmake >/dev/null 2>&1; then
        return
    fi

    echo "cmake not found. Installing via apt..."
    export DEBIAN_FRONTEND=noninteractive
    if command -v sudo >/dev/null 2>&1; then
        sudo apt-get update >/dev/null && sudo apt-get install -y cmake >/dev/null
    else
        apt-get update >/dev/null && apt-get install -y cmake >/dev/null
    fi
}

ensure_cmake

# Navigate to the Rust project directory
cd "$(dirname "$0")"

echo "Building Rust tests..."
cargo build --release --quiet

echo ""
echo "Running Rust connectivity tests..."
echo ""

cargo run --release --quiet
