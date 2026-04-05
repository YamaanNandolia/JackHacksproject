#!/usr/bin/env bash
# Run the full pipeline: Agents 1-5 → job file → VS Code + JacCoder
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$SCRIPT_DIR/automation/orchestrator.py" "$@"
