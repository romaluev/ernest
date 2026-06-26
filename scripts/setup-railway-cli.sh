#!/usr/bin/env bash
# Ensure Railway CLI is on PATH for the ernest user (Hostinger / any Ubuntu VPS).
set -euo pipefail
export PATH="$HOME/.local/bin:$PATH"

if command -v railway >/dev/null 2>&1; then
  echo "railway: $(railway --version 2>&1 | head -1)"
  exit 0
fi

command -v npm >/dev/null 2>&1 || {
  echo "npm required — Hermes setup should have installed Node." >&2
  exit 1
}

npm install -g @railway/cli
echo "railway: $(railway --version 2>&1 | head -1)"
