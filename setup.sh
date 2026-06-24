#!/usr/bin/env bash
#
# Ernest — one-line setup.
#
#   curl -fsSL https://raw.githubusercontent.com/romaluev/ernest/main/setup.sh | bash
#
# Installs Hermes if missing, installs the Ernest profile, connects a model
# (browser login — no API keys to paste), then drops you into onboarding.
# Everything else — apps, vault, voice, skills — happens in the chat.

set -euo pipefail

REPO="github.com/romaluev/ernest"
PROFILE="ernest"
TTY=/dev/tty

bold()  { printf '\n\033[1m%s\033[0m\n' "$*"; }
dim()   { printf '\033[2m%s\033[0m\n' "$*"; }
ask()   { local p="$1" d="${2:-}" a; printf '%s' "$p" >"$TTY"; read -r a <"$TTY" || true; printf '%s' "${a:-$d}"; }

command -v git >/dev/null 2>&1 || {
  echo "git is required. Install it first (macOS: xcode-select --install · Debian/Ubuntu: sudo apt install git curl xz-utils)." >&2
  exit 1
}

# 1 — Hermes runtime (skipped if already present)
if ! command -v hermes >/dev/null 2>&1; then
  bold "Installing Hermes (one time)…"
  curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash
  export PATH="$HOME/.local/bin:$PATH"
fi
command -v hermes >/dev/null 2>&1 || { echo "Hermes install did not put 'hermes' on PATH. Open a new terminal and re-run." >&2; exit 1; }

# 2 — Ernest profile (identity, config, skills, cron — all baked in)
bold "Installing Ernest…"
hermes profile install "$REPO" --name "$PROFILE" --alias --yes --force

ENV="${HERMES_HOME:-$HOME/.hermes}/profiles/$PROFILE/.env"
mkdir -p "$(dirname "$ENV")"; touch "$ENV"
put() { grep -q "^$1=" "$ENV" 2>/dev/null && return 0; [ -n "${2:-}" ] && printf '%s=%s\n' "$1" "$2" >>"$ENV"; }

# 3 — Apps + memory (can be skipped now and finished in chat)
bold "Connect apps & memory  (press Enter to skip — Ernest can do this in chat)"
dim   "Composio key powers HubSpot/Outlook/Slack/Calendar. Get one at https://dashboard.composio.dev"
put COMPOSIO_API_KEY "$(ask 'Composio API key (optional): ')"

DEFAULT_VAULT="$HOME/ErnestVault"
VAULT="$(ask "Obsidian vault folder [$DEFAULT_VAULT]: " "$DEFAULT_VAULT")"
mkdir -p "$VAULT"
put OBSIDIAN_VAULT_PATH "$VAULT"

# 4 — Model (browser OAuth: Nous Portal / OpenAI Codex / Anthropic — no keys to type)
bold "Connect a model  (browser login — choose Codex, Anthropic, or Nous Portal)"
hermes -p "$PROFILE" model <"$TTY" >"$TTY" 2>&1 || dim "Skipped — run 'ernest model' anytime to connect one."

# 5 — Onboarding chat does the rest
bold "Starting Ernest…"
exec hermes -p "$PROFILE" chat -s ernest-bootstrap <"$TTY" >"$TTY" 2>&1
