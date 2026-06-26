#!/usr/bin/env bash
# Headless Railway deploy from VPS — project token + project id.
#
#   RAILWAY_TOKEN=xxx ./scripts/railway-deploy-headless.sh \
#     --project 1751c4ef-6369-49ca-837d-d93d3c6a8811 \
#     --dir /tmp/deploy/skolkovo \
#     --environment production

set -euo pipefail

PROJECT=""
DIR="."
ENVIRONMENT="production"
SERVICE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project) PROJECT="$2"; shift 2 ;;
    --dir) DIR="$2"; shift 2 ;;
    --environment|-e) ENVIRONMENT="$2"; shift 2 ;;
    --service|-s) SERVICE="$2"; shift 2 ;;
    -h|--help)
      echo "Usage: RAILWAY_TOKEN=... $0 --project <id> [--dir path] [--environment name] [--service name]"
      exit 0
      ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

[[ -n "$PROJECT" ]] || { echo "--project is required" >&2; exit 1; }
[[ -n "${RAILWAY_TOKEN:-}" ]] || { echo "RAILWAY_TOKEN (project token) is required" >&2; exit 1; }
command -v railway >/dev/null 2>&1 || { echo "railway CLI not installed" >&2; exit 1; }

cd "$DIR"
args=(up --project "$PROJECT" --environment "$ENVIRONMENT" --detach)
[[ -n "$SERVICE" ]] && args+=(--service "$SERVICE")

echo "Deploying $(pwd) → project $PROJECT ($ENVIRONMENT)..."
railway "${args[@]}"
