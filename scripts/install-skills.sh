#!/usr/bin/env bash
# Install Ernest's curated, vetted skill library. Reuse-first: nothing here is
# authored by Ernest — these are existing, tested skills from the ecosystem.
set -uo pipefail

PROFILE="${ERNEST_PROFILE:-ernest}"
HERMES="hermes -p $PROFILE"

say()  { printf '\n\033[1m%s\033[0m\n' "$*"; }
try()  { echo "+ $*"; "$@" || echo "  (skipped — review and run manually if needed)"; }

say "Official (Anthropic) — installed automatically"
# Document skills (offers, proposals, spreadsheets, decks) + the meta skill that
# lets Ernest write new high-quality skills.
try $HERMES skills install official/document-skills/docx
try $HERMES skills install official/document-skills/pdf
try $HERMES skills install official/document-skills/pptx
try $HERMES skills install official/document-skills/xlsx
try $HERMES skills install github.com/anthropics/skills/skill-creator

say "Vetted community — review, then install (trust policy: case-by-case)"
cat <<'EOF'
Self-improvement loop:
  Hermes Dojo (measure -> evolve -> report):
    git clone https://github.com/Yonkoo11/hermes-dojo.git && cd hermes-dojo && ./install.sh

Anti-slop planning (Matt Pocock, 45k+ stars):
  hermes -p ernest skills install github.com/mattpocock/skills

App connectors ride on the Composio MCP (already wired in config.yaml):
  Connect HubSpot, Outlook, Outlook Calendar, Slack at https://app.composio.dev
  Optional behavioral wrappers from ComposioHQ/awesome-claude-skills:
    npx skills add ComposioHQ/awesome-claude-skills/hubspot-automation
    npx skills add ComposioHQ/awesome-claude-skills/outlook-automation
    npx skills add ComposioHQ/awesome-claude-skills/slack-automation

Sourcing:
  hermes -p ernest plugins enable browser/browser_use
EOF

say "Installed skills"
$HERMES skills list 2>/dev/null | tail -n +1
