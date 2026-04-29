#!/usr/bin/env bash
# scripts/run-local.sh — bootstrap & run clawhermesmanus locally (production-grade)
#
# Overrides:
#   REPO_DIR=/path     custom checkout location  (default: $HOME/chm)
#   BRANCH=dev         git branch                 (default: main)
#   SKIP_INSTALL=1     skip ./install.sh          (default: run if present)
#
set -euo pipefail

REPO_URL="https://github.com/Wallesters-org/clawhermesmanus.git"
REPO_DIR="${REPO_DIR:-$HOME/chm}"
BRANCH="${BRANCH:-main}"
SKIP_INSTALL="${SKIP_INSTALL:-0}"

REQUIRED_SECRETS=(OPENAI_API_KEY HERMES_API_KEY TELEGRAM_BOT_TOKEN GITHUB_TOKEN)

log()  { printf '\033[1;36m▶\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m⚠\033[0m %s\n' "$*" >&2; }
fail() { printf '\033[1;31m✗\033[0m %s\n' "$*" >&2; exit 1; }

log "[1/7] Checking prerequisites..."
for cmd in git docker; do
  command -v "$cmd" >/dev/null 2>&1 || fail "Missing dependency: $cmd"
done
docker compose version >/dev/null 2>&1 || fail "Missing: docker compose v2"
docker info >/dev/null 2>&1 || fail "Docker daemon is not running (start Docker Desktop / dockerd)"

log "[2/7] Cloning / updating repo at $REPO_DIR (branch: $BRANCH) ..."
if [ -d "$REPO_DIR/.git" ]; then
  git -C "$REPO_DIR" fetch origin "$BRANCH"
  git -C "$REPO_DIR" checkout "$BRANCH"
  git -C "$REPO_DIR" pull --ff-only origin "$BRANCH"
else
  git clone --branch "$BRANCH" "$REPO_URL" "$REPO_DIR"
fi
cd "$REPO_DIR"

log "[3/7] Preparing .env ..."
if [ ! -f .env ]; then
  if [ -f configs/.env.example ]; then
    cp configs/.env.example .env
  elif [ -f .env.example ]; then
    cp .env.example .env
  else
    cat > .env <<'EOF'
# --- Core ---
LOG_LEVEL=info
PORT=8000

# --- LLM keys (fill in) ---
OPENAI_API_KEY=
ANTHROPIC_API_KEY=
HERMES_API_KEY=

# --- Telegram gateway ---
TELEGRAM_BOT_TOKEN=
TELEGRAM_CHAT_ID=

# --- GitHub autonomy ---
GITHUB_TOKEN=
GITHUB_OWNER=Wallesters-org
GITHUB_REPO=clawhermesmanus
EOF
  fi
  chmod 600 .env
  warn "Created fresh .env at $REPO_DIR/.env — fill in your secrets, then re-run this script."
  exit 0
fi
chmod 600 .env

log "[4/7] Validating required secrets in .env ..."
missing=()
for key in "${REQUIRED_SECRETS[@]}"; do
  if grep -Eq "^${key}=$" .env || grep -Eq "^${key}=\"\"$" .env; then
    missing+=("$key")
  fi
done
if [ "${#missing[@]}" -gt 0 ]; then
  fail "Empty required secrets in .env: ${missing[*]}"
fi

log "[5/7] Running install.sh ..."
if [ "$SKIP_INSTALL" = "1" ]; then
  warn "SKIP_INSTALL=1 — skipping install.sh"
elif [ -f install.sh ]; then
  chmod +x install.sh
  ./install.sh || fail "install.sh failed (re-run with SKIP_INSTALL=1 to bypass)"
else
  warn "No install.sh found, skipping."
fi

log "[6/7] Building & starting docker compose stack ..."
docker compose pull || true
docker compose up --build -d

log "Waiting 5s for containers to settle..."
sleep 5
docker compose ps

log "[7/7] Tailing logs (Ctrl-C detaches; containers keep running) ..."
exec docker compose logs -f --tail=100
