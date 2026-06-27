#!/usr/bin/env bash
#
# Ernest — production VPS bootstrap (Ubuntu 22.04/24.04).
#
# Installs a always-on Ernest instance for a CEO: real Composio apps, Telegram gateway,
# watch crons, vault on disk, backups, firewall. CEO never SSHs — they use Telegram.
#
# 1. Create secrets file on the VPS (never commit this):
#
#      sudo install -m 600 /dev/null /root/ernest.secrets.env
#      sudo nano /root/ernest.secrets.env
#
#    Required:
#      ANTHROPIC_API_KEY=sk-ant-...
#      COMPOSIO_API_KEY=ck_...
#      TELEGRAM_BOT_TOKEN=123456789:ABC...    # from @BotFather
#      TELEGRAM_ALLOWED_USERS=123456789       # CEO numeric Telegram user ID
#    Optional:
#      TELEGRAM_HOME_CHANNEL=123456789        # chat ID for briefs/cron delivery
#      SLACK_BOT_TOKEN=xoxb-...               # Slack gateway (CEO can use Composio Slack instead)
#      SLACK_APP_TOKEN=xapp-...
#      SLACK_ALLOWED_USERS=U01234567
#      SLACK_HOME_CHANNEL=C01234567
#
# 2. Run (as root on fresh Ubuntu VPS):
#
#      curl -fsSL https://raw.githubusercontent.com/romaluev/ernest/main/scripts/vps-production-bootstrap.sh | bash -s -- \
#        --secrets /root/ernest.secrets.env \
#        --user ernest
#
# 3. CEO opens Telegram → DM @YourErnestBot → onboarding starts.

set -euo pipefail

SECRETS_FILE=""
LOCAL_REPO=""
RUN_USER="ernest"
ENABLE_CRONS=1
ENABLE_UFW=1
SKIP_BACKUP_CRON=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --secrets) SECRETS_FILE="$2"; shift 2 ;;
    --local-repo) LOCAL_REPO="$2"; shift 2 ;;
    --user) RUN_USER="$2"; shift 2 ;;
    --no-crons) ENABLE_CRONS=0; shift ;;
    --no-ufw) ENABLE_UFW=0; shift ;;
    --no-backup-cron) SKIP_BACKUP_CRON=1; shift ;;
    -h|--help)
      sed -n '2,30p' "$0"
      exit 0
      ;;
    *) echo "Unknown: $1 (try --help)" >&2; exit 1 ;;
  esac
done

[[ -n "$SECRETS_FILE" && -f "$SECRETS_FILE" ]] || {
  echo "ERROR: --secrets /path/to/ernest.secrets.env required (see script header)." >&2
  exit 1
}

# shellcheck disable=SC1090
set -a; source "$SECRETS_FILE"; set +a

[[ -n "${ANTHROPIC_API_KEY:-}" ]] || {
  echo "ERROR: secrets file needs ANTHROPIC_API_KEY." >&2
  exit 1
}
[[ -n "${COMPOSIO_API_KEY:-}" ]] || {
  echo "ERROR: secrets file needs COMPOSIO_API_KEY." >&2
  exit 1
}
[[ -n "${TELEGRAM_BOT_TOKEN:-}" && -n "${TELEGRAM_ALLOWED_USERS:-}" ]] || {
  echo "ERROR: secrets file needs TELEGRAM_BOT_TOKEN and TELEGRAM_ALLOWED_USERS." >&2
  exit 1
}

if [[ "$(id -u)" -eq 0 ]]; then
  SUDO=""
  apt-get update -qq
  DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    git curl xz-utils ca-certificates ufw rsync
  if ! id "$RUN_USER" &>/dev/null; then
    useradd -m -s /bin/bash "$RUN_USER"
  fi
  install -m 600 "$SECRETS_FILE" "/home/$RUN_USER/ernest.secrets.env"
  chown "$RUN_USER:$RUN_USER" "/home/$RUN_USER/ernest.secrets.env"
  SECRETS_FILE="/home/$RUN_USER/ernest.secrets.env"
else
  SUDO="sudo"
  $SUDO apt-get update -qq
  DEBIAN_FRONTEND=noninteractive $SUDO apt-get install -y -qq \
    git curl xz-utils ca-certificates ufw rsync
  RUN_USER="$(whoami)"
fi

if [[ -n "$LOCAL_REPO" && -d "$LOCAL_REPO" ]]; then
  chmod -R a+rX "$LOCAL_REPO"
fi

run_as() {
  if [[ "$(id -un)" == "$RUN_USER" ]]; then
    bash -c "$1"
  else
    su - "$RUN_USER" -c "$1"
  fi
}

# Firewall: SSH only (Telegram gateway uses outbound polling — no inbound ports)
if [[ "$ENABLE_UFW" -eq 1 ]] && command -v ufw >/dev/null 2>&1; then
  ufw --force reset >/dev/null 2>&1 || true
  ufw default deny incoming >/dev/null
  ufw default allow outgoing >/dev/null
  ufw allow OpenSSH >/dev/null
  ufw --force enable >/dev/null
fi

INSTALL_BODY=$(cat <<'INNER'
set -euo pipefail
export PATH="$HOME/.local/bin:$PATH"
set -a; source "$HOME/ernest.secrets.env"; set +a

export ERNEST_COMPOSIO_API_KEY="${COMPOSIO_API_KEY}"
export ERNEST_VAULT="${ERNEST_VAULT:-$HOME/ErnestVault}"
mkdir -p "$ERNEST_VAULT/Ernest"

# Seed a minimal VALID Obsidian vault so the obsidian MCP (memory backend) starts
# on a fresh box. The obsidian-mcp package refuses a directory without a parseable
# .obsidian/ config ("Not a valid Obsidian vault"), which silently degrades memory.
if [ ! -d "$ERNEST_VAULT/.obsidian" ]; then
  mkdir -p "$ERNEST_VAULT/.obsidian"
  printf '{}' > "$ERNEST_VAULT/.obsidian/app.json"
  printf '{}' > "$ERNEST_VAULT/.obsidian/appearance.json"
  printf '[]' > "$ERNEST_VAULT/.obsidian/core-plugins.json"
fi

# Headless Ernest install
LOCAL_REPO="__LOCAL_REPO__"
if [[ -n "$LOCAL_REPO" && -f "$LOCAL_REPO/setup.sh" ]]; then
  export ERNEST_REPO="$LOCAL_REPO"
  bash "$LOCAL_REPO/setup.sh"
else
  curl -fsSL https://raw.githubusercontent.com/romaluev/ernest/main/setup.sh | bash
fi

ENV="$HOME/.hermes/profiles/ernest/.env"
mkdir -p "$(dirname "$ENV")"

put() {
  local k="$1" v="$2"
  [[ -n "$v" ]] || return 0
  if grep -q "^${k}=" "$ENV" 2>/dev/null; then
    sed -i.bak "s|^${k}=.*|${k}=${v}|" "$ENV"
  else
    printf '%s=%s\n' "$k" "$v" >>"$ENV"
  fi
}
unset_env() {
  local k="$1"
  if grep -q "^${k}=" "$ENV" 2>/dev/null; then
    sed -i.bak "/^${k}=/d" "$ENV"
  fi
}

put ANTHROPIC_API_KEY "${ANTHROPIC_API_KEY}"
unset_env OPENROUTER_API_KEY
put COMPOSIO_API_KEY "${COMPOSIO_API_KEY}"
put OBSIDIAN_VAULT_PATH "$ERNEST_VAULT"
put TELEGRAM_BOT_TOKEN "${TELEGRAM_BOT_TOKEN}"
put TELEGRAM_ALLOWED_USERS "${TELEGRAM_ALLOWED_USERS}"
put TELEGRAM_HOME_CHANNEL "${TELEGRAM_HOME_CHANNEL:-}"
put SLACK_BOT_TOKEN "${SLACK_BOT_TOKEN:-}"
put SLACK_APP_TOKEN "${SLACK_APP_TOKEN:-}"
put SLACK_ALLOWED_USERS "${SLACK_ALLOWED_USERS:-}"
put SLACK_HOME_CHANNEL "${SLACK_HOME_CHANNEL:-}"
put RAILWAY_API_TOKEN "${RAILWAY_API_TOKEN:-}"
put RAILWAY_TOKEN "${RAILWAY_TOKEN:-}"

chmod 600 "$ENV" "$HOME/ernest.secrets.env"

if [[ -x /opt/ernest/scripts/setup-railway-cli.sh ]]; then
  bash /opt/ernest/scripts/setup-railway-cli.sh || true
fi

# Structural verify (no network)
bash "$HOME/.hermes/profiles/ernest/scripts/verify-ernest.sh" || true

# Gateway: start now; root installs system service after this block
nohup hermes -p ernest gateway run >> "$HOME/gateway.log" 2>&1 &
sleep 5

# Enable watch crons (need gateway for delivery)
ENABLE_CRONS="__ENABLE_CRONS__"
if [[ "$ENABLE_CRONS" == "1" ]]; then
  for job in ernest-daily-brief ernest-ambient-watch ernest-hubspot-hygiene; do
    hermes -p ernest cron resume "$job" || true
  done
fi

# Daily backup cron (profile export + vault tarball)
SKIP_BACKUP="__SKIP_BACKUP__"
if [[ "$SKIP_BACKUP" == "0" ]]; then
  BACKUP_SCRIPT="$HOME/.hermes/profiles/ernest/scripts/backup-ernest.sh"
  if [[ -x "$BACKUP_SCRIPT" ]]; then
    (crontab -l 2>/dev/null | grep -v backup-ernest.sh; echo "0 3 * * * $BACKUP_SCRIPT >> $HOME/ernest-backup.log 2>&1") | crontab -
  fi
fi

# Live connector check (best-effort)
hermes -p ernest mcp test composio && echo "Composio MCP: OK" || echo "Composio MCP: check COMPOSIO_API_KEY / dashboard connections"
hermes -p ernest mcp test obsidian && echo "Obsidian vault: OK" || echo "Obsidian vault: check npx/node"

hermes -p ernest gateway status || true
INNER
)

INSTALL_BODY="${INSTALL_BODY/__ENABLE_CRONS__/$ENABLE_CRONS}"
INSTALL_BODY="${INSTALL_BODY/__SKIP_BACKUP__/$SKIP_BACKUP_CRON}"
INSTALL_BODY="${INSTALL_BODY/__LOCAL_REPO__/$LOCAL_REPO}"

# Best-effort: a non-zero from a connector self-test (e.g. `mcp test composio`)
# must NOT abort the script before the boot-time systemd install below — that is
# the step that makes Ernest survive reboots. Guard it so install always proceeds.
run_as "$INSTALL_BODY" || echo "WARN: install steps returned non-zero; continuing to systemd install."

# System-level gateway (boot-time) — requires root
if [[ "$(id -u)" -eq 0 ]] && command -v systemctl >/dev/null 2>&1; then
  pkill -u "$RUN_USER" -f "hermes.*gateway" 2>/dev/null || true
  sleep 2
  export HOME="/home/$RUN_USER"
  export PATH="/home/$RUN_USER/.local/bin:$PATH"
  export HERMES_ACCEPT_HOOKS=1
  printf 'n\nn\n' | hermes -p ernest gateway install --system --run-as-user "$RUN_USER" --force 2>/dev/null || true
  systemctl daemon-reload 2>/dev/null || true
  systemctl enable hermes-gateway-ernest 2>/dev/null || true
  systemctl restart hermes-gateway-ernest 2>/dev/null || true
fi

echo ""
echo "=============================================="
echo " Ernest PRODUCTION VPS — ready for CEO"
echo "=============================================="
echo " User:     $RUN_USER"
echo " Profile:  ~$RUN_USER/.hermes/profiles/ernest/"
echo " Vault:    ~$RUN_USER/ErnestVault/"
echo " Secrets:  ~$RUN_USER/ernest.secrets.env (mode 600)"
echo ""
echo " CEO handoff (Telegram):"
echo "   1. DM @YourErnestBot in Telegram"
echo "   2. Say: Hi Ernest"
echo "   3. Ernest asks what to take off their plate → onboarding"
echo "   4. CEO clicks Composio Connect Links for Outlook, HubSpot, Calendar"
echo "   5. CEO can connect Slack via Composio now or later (optional)"
echo "   6. CEO tells Ernest what to watch (standing concerns)"
echo ""
echo " Operator checks:"
echo "   su - $RUN_USER -c 'hermes -p ernest gateway status'"
echo "   su - $RUN_USER -c 'hermes -p ernest cron list'"
echo "   su - $RUN_USER -c 'tail -f ~/.hermes/profiles/ernest/logs/agent.log'"
echo ""
echo "=============================================="
