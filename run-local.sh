#!/usr/bin/env bash
# run-local.sh — thin shim that delegates to scripts/run-local.sh
# Kept at repo root for the canonical curl-pipe install pattern.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$DIR/scripts/run-local.sh" "$@"
