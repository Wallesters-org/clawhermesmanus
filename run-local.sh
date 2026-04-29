#!/usr/bin/env bash
# run-local.sh — self-bootstrapping entry point.
#
# Two modes:
#   1) Run from inside a clone of the repo → delegates to scripts/run-local.sh
#   2) Run standalone (curl-piped into $HOME) → clones the repo first, then delegates
#
set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/Wallesters-org/clawhermesmanus.git}"
REPO_DIR="${REPO_DIR:-$HOME/chm}"
BRANCH="${BRANCH:-main}"

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -fx "$DIR/scripts/run-local.sh" ]; then
  exec "$DIR/scripts/run-local.sh" "$@"
fi

echo "▶ Bootstrap: scripts/run-local.sh not found next to this shim."
echo "▶ Cloning $REPO_URL (branch: $BRANCH) into $REPO_DIR ..."
command -v git >/dev/null 2>&1 || { echo "✗ git is required"; exit 1; }

if [ -d "$REPO_DIR/.git" ]; then
  git -C "$REPO_DIR" fetch origin "$BRANCH"
  git -C "$REPO_DIR" checkout "$BRANCH"
  git -C "$REPO_DIR" pull --ff-only origin "$BRANCH"
else
  git clone --branch "$BRANCH" "$REPO_URL" "$REPO_DIR"
fi

chmod +x "$REPO_DIR/scripts/run-local.sh"
exec "$REPO_DIR/scripts/run-local.sh" "$@"
