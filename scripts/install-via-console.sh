#!/usr/bin/env bash
# Run ON the server (web console or SSH). Paste exports first, then run this script.
#
#   export ANTHROPIC_API_KEY=sk-ant-...
#   export COMPOSIO_API_KEY=ck_...
#   export TELEGRAM_BOT_TOKEN=123456789:ABC...
#   export TELEGRAM_ALLOWED_USERS=123456789
#   curl -fsSL https://raw.githubusercontent.com/romaluev/ernest/main/scripts/install-via-console.sh | bash
#
# Private repo: copy ernest folder to /opt/ernest first, then:
#   export ERNEST_LOCAL=/opt/ernest && bash /opt/ernest/scripts/install-via-console.sh

set -euo pipefail

need() { [[ -n "${!1:-}" ]] || { echo "ERROR: export $1 first" >&2; exit 1; }; }
need ANTHROPIC_API_KEY
need COMPOSIO_API_KEY
need TELEGRAM_BOT_TOKEN
need TELEGRAM_ALLOWED_USERS

export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq git curl xz-utils ca-certificates ufw rsync

install -m 600 /dev/null /root/ernest.secrets.env
cat > /root/ernest.secrets.env <<EOF
ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}
COMPOSIO_API_KEY=${COMPOSIO_API_KEY}
TELEGRAM_BOT_TOKEN=${TELEGRAM_BOT_TOKEN}
TELEGRAM_ALLOWED_USERS=${TELEGRAM_ALLOWED_USERS}
TELEGRAM_HOME_CHANNEL=${TELEGRAM_HOME_CHANNEL:-}
SLACK_BOT_TOKEN=${SLACK_BOT_TOKEN:-}
SLACK_APP_TOKEN=${SLACK_APP_TOKEN:-}
SLACK_ALLOWED_USERS=${SLACK_ALLOWED_USERS:-}
SLACK_HOME_CHANNEL=${SLACK_HOME_CHANNEL:-}
EOF

LOCAL="${ERNEST_LOCAL:-}"
if [[ -n "$LOCAL" && -d "$LOCAL/scripts/vps-production-bootstrap.sh" ]]; then
  bash "$LOCAL/scripts/vps-production-bootstrap.sh" --secrets /root/ernest.secrets.env --local-repo "$LOCAL"
else
  curl -fsSL https://raw.githubusercontent.com/romaluev/ernest/main/scripts/vps-production-bootstrap.sh -o /tmp/vps-bootstrap.sh
  bash /tmp/vps-bootstrap.sh --secrets /root/ernest.secrets.env
fi

echo "DONE. CEO: Telegram → DM @YourErnestBot → Hi Ernest"
