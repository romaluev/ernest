#!/usr/bin/env bash
# Finish Ernest VPS setup after secrets are populated (Telegram gateway + crons).
# Run as ernest: bash /opt/ernest/scripts/finish-vps-setup.sh
# Or as root after updating secrets: su - ernest -c 'bash /opt/ernest/scripts/finish-vps-setup.sh'
set -euo pipefail
export PATH="$HOME/.local/bin:$PATH"
set -a; source "$HOME/ernest.secrets.env"; set +a

need() { [[ -n "${!1:-}" ]] || { echo "Missing $1 in ~/ernest.secrets.env"; exit 1; }; }
need ANTHROPIC_API_KEY
need COMPOSIO_API_KEY TELEGRAM_BOT_TOKEN TELEGRAM_ALLOWED_USERS

ENV="$HOME/.hermes/profiles/ernest/.env"
mkdir -p "$(dirname "$ENV")"; touch "$ENV"
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
put OBSIDIAN_VAULT_PATH "${ERNEST_VAULT:-$HOME/ErnestVault}"
put TELEGRAM_BOT_TOKEN "${TELEGRAM_BOT_TOKEN}"
put TELEGRAM_ALLOWED_USERS "${TELEGRAM_ALLOWED_USERS}"
put TELEGRAM_HOME_CHANNEL "${TELEGRAM_HOME_CHANNEL:-${TELEGRAM_ALLOWED_USERS%%,*}}"
put SLACK_BOT_TOKEN "${SLACK_BOT_TOKEN:-}"
put SLACK_APP_TOKEN "${SLACK_APP_TOKEN:-}"
put SLACK_ALLOWED_USERS "${SLACK_ALLOWED_USERS:-}"
put SLACK_HOME_CHANNEL "${SLACK_HOME_CHANNEL:-}"
put RAILWAY_API_TOKEN "${RAILWAY_API_TOKEN:-}"
put RAILWAY_TOKEN "${RAILWAY_TOKEN:-}"
chmod 600 "$ENV" "$HOME/ernest.secrets.env"

# Railway CLI (headless deploy on VPS)
SETUP_RAILWAY="/opt/ernest/scripts/setup-railway-cli.sh"
[[ -x "$SETUP_RAILWAY" ]] && bash "$SETUP_RAILWAY" || true
VERIFY_RAILWAY="/opt/ernest/scripts/railway-verify.sh"
[[ -x "$VERIFY_RAILWAY" ]] && bash "$VERIFY_RAILWAY" || true

# Headless Obsidian vault (.obsidian/ required by obsidian-mcp)
INIT_VAULT="$HOME/.hermes/profiles/ernest/scripts/init-obsidian-vault.sh"
if [[ -x "$INIT_VAULT" ]]; then
  bash "$INIT_VAULT" "${ERNEST_VAULT:-$HOME/ErnestVault}"
elif [[ -x /opt/ernest/scripts/init-obsidian-vault.sh ]]; then
  bash /opt/ernest/scripts/init-obsidian-vault.sh "${ERNEST_VAULT:-$HOME/ErnestVault}"
fi

if [[ -d /opt/ernest ]]; then
  hermes profile install /opt/ernest --name ernest --yes --force 2>/dev/null || true
fi

bash "$HOME/.hermes/profiles/ernest/scripts/verify-ernest.sh" || true

pkill -u "$(whoami)" -f "hermes.*gateway" 2>/dev/null || true
sleep 2
if systemctl is-enabled hermes-gateway-ernest.service &>/dev/null; then
  sudo systemctl restart hermes-gateway-ernest 2>/dev/null || systemctl --user restart hermes-gateway-ernest 2>/dev/null || {
    nohup hermes -p ernest gateway run >> "$HOME/gateway.log" 2>&1 &
  }
else
  nohup hermes -p ernest gateway run >> "$HOME/gateway.log" 2>&1 &
fi
sleep 5

for job in ernest-daily-brief ernest-ambient-watch ernest-hubspot-hygiene; do
  hermes -p ernest cron resume "$job" || true
done

BACKUP="$HOME/.hermes/profiles/ernest/scripts/backup-ernest.sh"
if [[ -x "$BACKUP" ]]; then
  (crontab -l 2>/dev/null | grep -v backup-ernest.sh; echo "0 3 * * * $BACKUP >> $HOME/ernest-backup.log 2>&1") | crontab -
fi

hermes -p ernest mcp test composio && echo "Composio: OK" || echo "Composio: check key"
hermes -p ernest mcp test obsidian && echo "Obsidian: OK" || echo "Obsidian: check vault"
hermes -p ernest gateway status || true
hermes -p ernest cron status || true
echo "DONE — CEO can DM the bot in Telegram: Hi Ernest"
echo "Tip (root): systemctl restart hermes-gateway-ernest for boot-time service"
