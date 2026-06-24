#!/usr/bin/env bash
#
# Ernest — VPS demo bootstrap (Ubuntu 22.04/24.04).
# CEO does NOT install anything locally. They talk to Ernest via Telegram or Slack.
#
# Run on a fresh VPS as root or sudo user:
#
#   curl -fsSL https://raw.githubusercontent.com/romaluev/ernest/main/scripts/vps-demo-bootstrap.sh | bash -s -- \
#     --anthropic-key "sk-ant-..." \
#     --composio-key "ck_..." \
#     --telegram-token "123:ABC..." \
#     --telegram-ceo-id "123456789"
#
# Or export vars and run without args (see below).

set -euo pipefail

ANTHROPIC_KEY="${ANTHROPIC_API_KEY:-}"
COMPOSIO_KEY="${ERNEST_COMPOSIO_API_KEY:-${COMPOSIO_API_KEY:-}}"
TELEGRAM_TOKEN="${TELEGRAM_BOT_TOKEN:-}"
TELEGRAM_CEO="${TELEGRAM_ALLOWED_USERS:-}"
SLACK_BOT="${SLACK_BOT_TOKEN:-}"
SLACK_APP="${SLACK_APP_TOKEN:-}"
SLACK_CEO="${SLACK_ALLOWED_USERS:-}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --anthropic-key) ANTHROPIC_KEY="$2"; shift 2 ;;
    --composio-key)  COMPOSIO_KEY="$2"; shift 2 ;;
    --telegram-token) TELEGRAM_TOKEN="$2"; shift 2 ;;
    --telegram-ceo-id) TELEGRAM_CEO="$2"; shift 2 ;;
    --slack-bot) SLACK_BOT="$2"; shift 2 ;;
    --slack-app) SLACK_APP="$2"; shift 2 ;;
    --slack-ceo-id) SLACK_CEO="$2"; shift 2 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

if [[ "$(id -u)" -eq 0 ]]; then
  SUDO=""
  apt-get update -qq
  apt-get install -y -qq git curl xz-utils ca-certificates
else
  SUDO="sudo"
  $SUDO apt-get update -qq
  $SUDO apt-get install -y -qq git curl xz-utils ca-certificates
fi

export PATH="$HOME/.local/bin:$PATH"
export ERNEST_COMPOSIO_API_KEY="${COMPOSIO_KEY}"
export ERNEST_VAULT="${ERNEST_VAULT:-$HOME/ErnestVault}"

# Headless install (no TTY → skips OAuth; you must pass API keys below)
curl -fsSL https://raw.githubusercontent.com/romaluev/ernest/main/setup.sh | bash

ENV="${HERMES_HOME:-$HOME/.hermes}/profiles/ernest/.env"
mkdir -p "$(dirname "$ENV")"
touch "$ENV"

put() {
  local k="$1" v="$2"
  [[ -n "$v" ]] || return 0
  grep -q "^${k}=" "$ENV" 2>/dev/null && sed -i.bak "s|^${k}=.*|${k}=${v}|" "$ENV" || printf '%s=%s\n' "$k" "$v" >>"$ENV"
}

put ANTHROPIC_API_KEY "$ANTHROPIC_KEY"
put COMPOSIO_API_KEY "$COMPOSIO_KEY"
put OBSIDIAN_VAULT_PATH "$ERNEST_VAULT"
put TELEGRAM_BOT_TOKEN "$TELEGRAM_TOKEN"
put TELEGRAM_ALLOWED_USERS "$TELEGRAM_CEO"
put SLACK_BOT_TOKEN "$SLACK_BOT"
put SLACK_APP_TOKEN "$SLACK_APP"
put SLACK_ALLOWED_USERS "$SLACK_CEO"

if [[ -z "$ANTHROPIC_KEY" ]] && ! grep -q "^OPENROUTER_API_KEY=" "$ENV" 2>/dev/null; then
  echo "ERROR: Set ANTHROPIC_API_KEY (or OPENROUTER_API_KEY in $ENV). OAuth won't work headless on VPS." >&2
  exit 1
fi

if [[ -z "$TELEGRAM_TOKEN" && -z "$SLACK_BOT" ]]; then
  echo "ERROR: Pass --telegram-token + --telegram-ceo-id OR Slack tokens. CEO needs a chat surface." >&2
  exit 1
fi

# Gateway as systemd service (runs 24/7)
hermes -p ernest gateway install 2>/dev/null || true
hermes -p ernest gateway start

echo ""
echo "=========================================="
echo " Ernest VPS demo is up."
echo "=========================================="
echo " Profile:  ~/.hermes/profiles/ernest/"
echo " Vault:    $ERNEST_VAULT"
echo ""
if [[ -n "$TELEGRAM_TOKEN" ]]; then
  echo " CEO: open Telegram → find your bot → send:"
  echo "   /start"
  echo "   I'm Ernest. What's the one thing you'd most like off your plate right now?"
  echo ""
fi
if [[ -n "$SLACK_BOT" ]]; then
  echo " CEO: Slack DM @YourBot or /invite in a channel"
  echo ""
fi
echo " Check:    hermes -p ernest gateway status"
echo " Logs:     tail -f ~/.hermes/profiles/ernest/logs/agent.log"
echo " Composio: CEO authorizes apps when Ernest sends Connect Links in chat"
echo "=========================================="
