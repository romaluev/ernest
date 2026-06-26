#!/usr/bin/env bash
# Verify Railway CLI + tokens on the Ernest VPS.
set -euo pipefail
export PATH="$HOME/.local/bin:$PATH"

ENV="${HOME}/.hermes/profiles/ernest/.env"
if [[ -f "$ENV" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV"
  set +a
fi

if ! command -v railway >/dev/null 2>&1; then
  echo "Railway CLI: NOT INSTALLED (run scripts/setup-railway-cli.sh)"
  exit 1
fi

echo "Railway CLI: $(railway --version 2>&1 | head -1)"

if [[ -n "${RAILWAY_API_TOKEN:-}" ]]; then
  if RAILWAY_API_TOKEN="$RAILWAY_API_TOKEN" railway whoami 2>&1; then
    echo "RAILWAY_API_TOKEN: OK (account — link/create projects)"
  else
    echo "RAILWAY_API_TOKEN: invalid or expired"
    exit 1
  fi
else
  echo "RAILWAY_API_TOKEN: not set (optional — add to ~/ernest.secrets.env)"
fi

if [[ -n "${RAILWAY_TOKEN:-}" ]]; then
  echo "RAILWAY_TOKEN: set (project deploy token)"
else
  echo "RAILWAY_TOKEN: not set (paste per-project token when deploying, or add to secrets)"
fi
