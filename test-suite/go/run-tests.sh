#!/bin/bash
# Go test runner script
# Usage: ./run-tests.sh

set -e

# Navigate to the Go module directory
cd "$(dirname "$0")"

echo "Installing Go dependencies..."
go mod download
go mod tidy

echo ""
echo "Running Go connectivity tests..."
echo ""

go run .
