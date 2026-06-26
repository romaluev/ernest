#!/usr/bin/env bash
# Daily backup: Ernest profile export + Obsidian vault tarball.
# Installed by vps-production-bootstrap.sh at 03:00 server time.
set -euo pipefail

export PATH="$HOME/.local/bin:$PATH"
STAMP="$(date +%Y%m%d-%H%M)"
DEST="${ERNEST_BACKUP_DIR:-$HOME/ernest-backups}"
mkdir -p "$DEST"

command -v hermes >/dev/null 2>&1 || { echo "hermes not on PATH"; exit 1; }

hermes profile export ernest -o "$DEST/profile-$STAMP.tar.gz" || echo "profile export skipped"

VAULT="${OBSIDIAN_VAULT_PATH:-$HOME/ErnestVault}"
if [[ -d "$VAULT" ]]; then
  tar -czf "$DEST/vault-$STAMP.tar.gz" -C "$(dirname "$VAULT")" "$(basename "$VAULT")"
fi

# Keep last 14 days
find "$DEST" -type f -mtime +14 -delete 2>/dev/null || true
echo "[$STAMP] backup done → $DEST"
