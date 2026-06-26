#!/usr/bin/env bash
# Initialize a headless Obsidian vault for Ernest (obsidian-mcp requires .obsidian/).
set -euo pipefail

VAULT="${1:-${OBSIDIAN_VAULT_PATH:-$HOME/ErnestVault}}"
mkdir -p "$VAULT/Ernest" "$VAULT/.obsidian"

# Minimal Obsidian vault metadata (obsidian-mcp validates this exists)
if [[ ! -f "$VAULT/.obsidian/app.json" ]]; then
  echo '{}' > "$VAULT/.obsidian/app.json"
fi
if [[ ! -f "$VAULT/.obsidian/core-plugins.json" ]]; then
  echo '["file-explorer","global-search","switcher","graph","backlink","canvas","outgoing-link","tag-pane","page-preview","daily-notes","templates","note-composer","command-palette","editor-status","bookmarks","markdown-importer","outline","word-count","slides","audio-recorder","workspaces","file-recovery","sync","publish"]' \
    > "$VAULT/.obsidian/core-plugins.json"
fi
if [[ ! -f "$VAULT/.obsidian/appearance.json" ]]; then
  echo '{"theme":"obsidian"}' > "$VAULT/.obsidian/appearance.json"
fi

# Seed Ernest memory templates from profile if available
PROFILE="${HERMES_HOME:-$HOME/.hermes}/profiles/ernest"
if [[ -d "$PROFILE/memory" ]]; then
  cp -an "$PROFILE/memory/." "$VAULT/Ernest/" 2>/dev/null || true
fi
if [[ -d /opt/ernest/memory ]]; then
  cp -an /opt/ernest/memory/. "$VAULT/Ernest/" 2>/dev/null || true
fi

echo "Obsidian vault ready: $VAULT"
