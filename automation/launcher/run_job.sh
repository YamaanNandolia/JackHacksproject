#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# run_job.sh — thin wrapper around launch_generated_app.py
#
# Usage:
#   ./run_job.sh <path-to-job.json> [--no-scaffold] [--no-vscode]
#
# Example:
#   ./run_job.sh ../../jobs/sample_job.json
# ---------------------------------------------------------------------------
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAUNCHER="${SCRIPT_DIR}/launch_generated_app.py"

# ---- Guard: job file argument required ------------------------------------
if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <path-to-job.json> [--no-scaffold] [--no-vscode]" >&2
    exit 1
fi

JOB_FILE="$1"
shift  # remaining args passed through to Python launcher

# ---- Guard: Python 3 available --------------------------------------------
if ! command -v python3 &>/dev/null; then
    echo "[ERROR] python3 not found in PATH." >&2
    exit 1
fi

# ---- Guard: launcher script exists ----------------------------------------
if [[ ! -f "$LAUNCHER" ]]; then
    echo "[ERROR] Launcher not found: $LAUNCHER" >&2
    exit 1
fi

echo "[run_job.sh] Invoking launcher for: $JOB_FILE"
python3 "$LAUNCHER" "$JOB_FILE" "$@"
