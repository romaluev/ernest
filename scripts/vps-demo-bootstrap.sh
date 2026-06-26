#!/usr/bin/env bash
#
# DEPRECATED — use vps-production-bootstrap.sh for real CEO deployments.
#
# This wrapper kept for old links. For production (real data, Telegram, crons, backups):
#
#   curl -fsSL .../scripts/vps-production-bootstrap.sh | bash -s -- \
#     --secrets /root/ernest.secrets.env
#
# See docs/vps-production.md

set -euo pipefail
echo "NOTE: vps-demo-bootstrap.sh is deprecated. Using vps-production-bootstrap.sh." >&2
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec bash "$DIR/vps-production-bootstrap.sh" "$@"
