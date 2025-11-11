#!/usr/bin/env bash
# Master runner for the devcontainer validation suite.
set -euo pipefail

STOP_ON_FAILURE="${STOP_ON_FAILURE:-0}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$ROOT/logs"
mkdir -p "$LOG_DIR"
RUN_ID="$(date +%Y%m%d-%H%M%S)"
LOG_FILE="$LOG_DIR/run-$RUN_ID.log"

overall_status=0

log_and_run() {
  local title=$1
  shift
  echo -e "\n=============================="
  echo ">> ${title}"
  echo "=============================="
  echo -e "\n[${title}] starting..." | tee -a "$LOG_FILE" >/dev/null
  if (set -o pipefail; "$@" 2>&1 | tee -a "$LOG_FILE"); then
    echo "[${title}] ✅ success" | tee -a "$LOG_FILE" >/dev/null
  else
    echo "[${title}] ❌ failed" | tee -a "$LOG_FILE" >/dev/null
    overall_status=1
    if [ "$STOP_ON_FAILURE" = "1" ]; then
      echo "STOP_ON_FAILURE=1 set: exiting after first failure." | tee -a "$LOG_FILE"
      exit 1
    fi
  fi
}

PY_DIR="$ROOT/python"
NODE_DIR="$ROOT/node"
GO_DIR="$ROOT/go"
RUST_DIR="$ROOT/rust"

# ==============================================================================
# TIER 1: Container Health Verification
# ==============================================================================
echo ""
echo "=========================================="
echo "TIER 1: Container Health Verification"
echo "=========================================="

log_and_run "Setup containers" bash -c "cd \"$ROOT\" && bash setup-containers.sh"

if command -v docker >/dev/null 2>&1; then
  log_and_run "Container verification" bash -c "cd \"$ROOT\" && bash verify-containers.sh"
else
  echo "docker CLI not found in PATH. Skipping container verification step." | tee -a "$LOG_FILE"
fi

# ==============================================================================
# TIER 2: Runtime & Package Manager Verification
# ==============================================================================
echo ""
echo "=========================================="
echo "TIER 2: Runtime & Package Manager Verification"
echo "=========================================="

log_and_run "Runtime verification" bash -c "cd \"$ROOT\" && bash verify-runtimes.sh"

# ==============================================================================
# TIER 3: Service Connectivity Tests (Python, Node, Go, Rust)
# ==============================================================================
echo ""
echo "=========================================="
echo "TIER 3: Service Connectivity Tests"
echo "=========================================="

if command -v uv >/dev/null 2>&1; then
  log_and_run "Python connectivity suite" bash -c "
    set -euo pipefail
    cd \"$PY_DIR\"
    UV_CACHE_DIR=\"$ROOT/.uv-cache\" uv sync
    source .venv/bin/activate
    python run_tests.py
  "
else
  echo "uv CLI not found in PATH. Python suite requires uv for dependency management." | tee -a "$LOG_FILE"
  overall_status=1
fi

log_and_run "Node.js connectivity suite" bash -c "
  set -euo pipefail
  cd \"$NODE_DIR\"
  npm install
  npm test
"

if command -v go >/dev/null 2>&1; then
  log_and_run "Go connectivity suite" bash -c "
    set -euo pipefail
    cd \"$GO_DIR\"
    bash run-tests.sh
  "
else
  echo "go CLI not found in PATH. Skipping Go connectivity suite." | tee -a "$LOG_FILE"
fi

if command -v cargo >/dev/null 2>&1; then
  log_and_run "Rust connectivity suite" bash -c "
    set -euo pipefail
    cd \"$RUST_DIR\"
    bash run-tests.sh
  "
else
  echo "cargo CLI not found in PATH. Skipping Rust connectivity suite." | tee -a "$LOG_FILE"
fi

echo -e "\n========================================"
if [ $overall_status -eq 0 ]; then
  echo "Devcontainer validation finished successfully."
else
  echo "Devcontainer validation finished with failures."
fi
echo "Full log: $LOG_FILE"
echo "========================================"

exit $overall_status
