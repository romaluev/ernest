#!/usr/bin/env bash
# Save a CEO-pasted secret from Telegram/Slack — no Hostinger/SSH needed.
#
#   bash /opt/ernest/scripts/ernest-set-secret.sh RAILWAY_API_TOKEN 'full-token-here'
#
# Updates profile .env and ~/ernest.secrets.env (mode 600). Never prints the value.

set -euo pipefail
export PATH="$HOME/.local/bin:$PATH"

KEY="${1:-}"
VALUE="${2:-}"

[[ -n "$KEY" && -n "$VALUE" ]] || {
  echo "Usage: $0 KEY VALUE" >&2
  exit 1
}

# CEO may set integration keys via chat. Operator/bootstrap keys stay off-limits.
ALLOW=(
  RAILWAY_API_TOKEN
  RAILWAY_TOKEN
  COMPOSIO_API_KEY
  ANTHROPIC_API_KEY
)
BLOCK=(
  TELEGRAM_BOT_TOKEN
  TELEGRAM_ALLOWED_USERS
  TELEGRAM_HOME_CHANNEL
  SLACK_BOT_TOKEN
  SLACK_APP_TOKEN
  SLACK_ALLOWED_USERS
  SLACK_HOME_CHANNEL
  OPENROUTER_API_KEY
)

allowed=0
for k in "${ALLOW[@]}"; do
  [[ "$KEY" == "$k" ]] && allowed=1 && break
done
[[ "$allowed" -eq 1 ]] || {
  echo "ERROR: $KEY cannot be set via chat (operator-only or unknown)." >&2
  exit 1
}
for k in "${BLOCK[@]}"; do
  [[ "$KEY" == "$k" ]] && {
    echo "ERROR: $KEY is operator-only." >&2
    exit 1
  }
done

# Reject truncated / redacted paste
if [[ "$VALUE" == *"..."* ]] || [[ ${#VALUE} -lt 8 ]]; then
  echo "ERROR: value looks truncated — paste the full key." >&2
  exit 1
fi

put_env() {
  local file="$1" k="$2" v="$3"
  mkdir -p "$(dirname "$file")"
  touch "$file"
  if grep -q "^${k}=" "$file" 2>/dev/null; then
    sed -i.bak "s|^${k}=.*|${k}=${v}|" "$file"
  else
    printf '%s=%s\n' "$k" "$v" >>"$file"
  fi
  chmod 600 "$file"
}

PROFILE_ENV="${HOME}/.hermes/profiles/ernest/.env"
SECRETS="${HOME}/ernest.secrets.env"

put_env "$PROFILE_ENV" "$KEY" "$VALUE"
put_env "$SECRETS" "$KEY" "$VALUE"

# Hermes CLI path (also updates active profile .env when HERMES_HOME is set)
if command -v hermes >/dev/null 2>&1; then
  HERMES_HOME="${HOME}/.hermes/profiles/ernest" hermes -p ernest config set "$KEY" "$VALUE" >/dev/null 2>&1 || true
fi

case "$KEY" in
  RAILWAY_*)
    if [[ -x /opt/ernest/scripts/railway-verify.sh ]]; then
      bash /opt/ernest/scripts/railway-verify.sh 2>&1 | grep -v '^Unauthorized' || true
    fi
    ;;
esac

echo "OK: $KEY saved (not shown). Ready to use."
