#!/usr/bin/env bash
set -euo pipefail

# build.sh — Thin wrapper around scripts/build.py.
# Usage:
#   bash scripts/build.sh              # Full build (generate + validate)
#   bash scripts/build.sh --validate   # Validate only, no generation
#   bash scripts/build.sh --check      # Check generated files are in sync (CI use)
#
# The original pure-bash implementation forked ~10 subprocesses per prompt
# file and stopped scaling once the repo passed a few hundred prompts. The
# logic now lives in build.py (stdlib only, single pass).

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if ! command -v python3 >/dev/null 2>&1; then
    echo "ERROR: python3 is required to build this repo" >&2
    exit 1
fi

exec python3 "$ROOT/scripts/build.py" "${1:-build}"
