# clawhermesmanus
Hybrid AI agent: OpenClaw + Hermes + OpenManus. GitHub autonomy, multi-LLM, Telegram gateway.

## Run locally

Requirements: `git`, `docker`, `docker compose v2`.

```bash
curl -fsSL https://raw.githubusercontent.com/Wallesters-org/clawhermesmanus/main/run-local.sh -o run-local.sh
chmod +x run-local.sh
./run-local.sh
```

The script clones the repo to `~/chm`, creates a `.env` (chmod 600) on first run and exits so you can fill in secrets, then on second run validates required secrets, runs `install.sh`, and starts the Docker stack.

### Overrides

| Variable       | Default       | Purpose                                  |
|----------------|---------------|------------------------------------------|
| `REPO_DIR`     | `$HOME/chm`   | Custom checkout location                 |
| `BRANCH`       | `main`        | Git branch to track                      |
| `SKIP_INSTALL` | `0`           | Set to `1` to skip `./install.sh`        |

Example: `BRANCH=dev REPO_DIR=/srv/chm ./run-local.sh`

### Required secrets in `.env`

`OPENAI_API_KEY`, `HERMES_API_KEY`, `TELEGRAM_BOT_TOKEN`, `GITHUB_TOKEN` — the script aborts if any are empty.

### Stop / clean

```bash
cd ~/chm && docker compose down            # stop
docker compose down -v --rmi local         # full clean (volumes + local images)
```
