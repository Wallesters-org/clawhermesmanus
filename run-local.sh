#!/usr/bin/env bash
# run-local.sh — bootstrap & run clawhermesmanus locally
set -euo pipefail

REPO_URL="https://github.com/Wallesters-org/clawhermesmanus.git"
REPO_DIR="${REPO_DIR:-$HOME/chm}"
BRANCH="${BRANCH:-main}"

echo "▶ [1/6] Checking prerequisites..."
for cmd in git docker; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "✗ Missing: $cmd"; exit 1; }
done
docker compose version >/dev/null 2>&1 || { echo "✗ Missing: docker compose v2"; exit 1; }

echo "▶ [2/6] Cloning / updating repo at $REPO_DIR ..."
if [ -d "$REPO_DIR/.git" ]; then
  git -C "$REPO_DIR" fetch origin "$BRANCH"
  git -C "$REPO_DIR" checkout "$BRANCH"
  git -C "$REPO_DIR" pull --ff-only origin "$BRANCH"
else
  git clone --branch "$BRANCH" "$REPO_URL" "$REPO_DIR"
fi
cd "$REPO_DIR"

echo "▶ [3/6] Preparing .env ..."
if [ ! -f .env ]; then
  if [ -f configs/.env.example ]; then
    cp configs/.env.example .env
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
  echo "  ⚠ Edit $REPO_DIR/.env and add your secrets, then re-run."
fi

echo "▶ [4/6] Running install.sh (if present) ..."
if [ -f install.sh ]; then
  chmod +x install.sh
  ./install.sh || echo "  ⚠ install.sh exited non-zero, continuing."
fi

echo "▶ [5/6] Building & starting stack via docker compose ..."
docker compose pull || true
docker compose up --build -d

echo "▶ [6/6] Tailing logs (Ctrl-C to detach; containers keep running) ..."
docker compose ps
docker compose logs -f --tail=100
