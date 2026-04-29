#!/usr/bin/env bash
set -euo pipefail

# ClawHermesManus installer
# Hybrid: OpenClaw + Hermes + OpenManus

CHM_HOME="${CHM_HOME:-$HOME/.chm}"
CHM_REPO="${CHM_REPO:-https://github.com/Wallesters-org/clawhermesmanus.git}"

log() { printf '\033[1;36m[CHM]\033[0m %s\n' "$*"; }
err() { printf '\033[1;31m[ERR]\033[0m %s\n' "$*" >&2; exit 1; }

log "Installing ClawHermesManus -> $CHM_HOME"

# OS detection
OS="$(uname -s)"
case "$OS" in
  Darwin)
    command -v brew >/dev/null || err "Install Homebrew first: https://brew.sh"
    for pkg in uv node ripgrep ffmpeg gh deno git; do
      brew list "$pkg" >/dev/null 2>&1 || brew install "$pkg"
    done
    ;;
  Linux)
    if command -v apt-get >/dev/null; then
      sudo apt-get update -y
      sudo apt-get install -y git ripgrep ffmpeg curl build-essential
      curl -fsSL https://astral.sh/uv/install.sh | sh
      curl -fsSL https://deno.land/install.sh | sh
      curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
      echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list
      sudo apt-get update -y && sudo apt-get install -y gh
    fi
    ;;
  *) err "Unsupported OS: $OS" ;;
esac

# Clone or update
if [ -d "$CHM_HOME/.git" ]; then
  log "Updating existing install"
  git -C "$CHM_HOME" pull --rebase --autostash
else
  log "Cloning $CHM_REPO"
  git clone "$CHM_REPO" "$CHM_HOME"
fi

cd "$CHM_HOME"

# Python venv via UV
log "Creating Python 3.11 venv"
uv venv --python 3.11 .venv
# shellcheck disable=SC1091
source .venv/bin/activate
uv pip install -e ".[all]" || log "pyproject.toml not yet present, skipping pip install"

# Node deps
[ -f package.json ] && npm install --silent || true

# Global CLI shim
SHIM="/usr/local/bin/chm"
log "Registering global CLI: $SHIM"
sudo tee "$SHIM" >/dev/null <<EOSHIM
#!/usr/bin/env bash
exec "$CHM_HOME/.venv/bin/python" -m chm "\$@"
EOSHIM
sudo chmod +x "$SHIM"

# Config bootstrap
mkdir -p "$HOME/.config/chm"
if [ ! -f "$HOME/.config/chm/config.toml" ] && [ -f "$CHM_HOME/configs/config.toml.template" ]; then
  cp "$CHM_HOME/configs/config.toml.template" "$HOME/.config/chm/config.toml"
  log "Config template copied to ~/.config/chm/config.toml"
fi

log "Done. Run: chm setup"
