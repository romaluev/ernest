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

# Interactive only if a real terminal is reachable. Under `curl | bash` over a
# pipe, stdin is the script — but /dev/tty still points at the terminal. With
# no tty at all (CI, ssh -T, some sandboxes) we skip prompts and print steps.
if { true >"$TTY"; } 2>/dev/null && { true <"$TTY"; } 2>/dev/null; then
  HAS_TTY=1
else
  HAS_TTY=0
fi

bold()  { printf '\n\033[1m%s\033[0m\n' "$*"; }
dim()   { printf '\033[2m%s\033[0m\n' "$*"; }
ask()   {
  local p="$1" d="${2:-}" a
  if [ "$HAS_TTY" = 1 ]; then
    printf '%s' "$p" >"$TTY"
    read -r a <"$TTY" || a=""
    printf '%s' "${a:-$d}"
  else
    printf '%s' "$d"
  fi
}

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
if ! hermes profile install "$REPO" --name "$PROFILE" --alias --yes --force; then
  echo "Profile install failed — check network/git access to $REPO and re-run." >&2
  exit 1
fi

ENV="${HERMES_HOME:-$HOME/.hermes}/profiles/$PROFILE/.env"
mkdir -p "$(dirname "$ENV")"; touch "$ENV"
put() {
  grep -q "^$1=" "$ENV" 2>/dev/null && return 0
  [ -n "${2:-}" ] && printf '%s=%s\n' "$1" "$2" >>"$ENV"
  return 0  # never fail the script just because a value was skipped
}

# 3 — Apps + memory (can be skipped now and finished in chat)
bold "Connect apps & memory  (press Enter to skip — Ernest can do this in chat)"
dim   "Composio key powers HubSpot/Outlook/Slack/Calendar. Get one at https://dashboard.composio.dev"
put COMPOSIO_API_KEY "$(ask 'Composio API key (optional): ')"

DEFAULT_VAULT="$HOME/ErnestVault"
VAULT="$(ask "Obsidian vault folder [$DEFAULT_VAULT]: " "$DEFAULT_VAULT")"
mkdir -p "$VAULT"
put OBSIDIAN_VAULT_PATH "$VAULT"

# 4 — Model (browser OAuth: Nous Portal / OpenAI Codex / Anthropic — no keys to type)
# 5 — Onboarding chat does the rest. Both need a terminal; without one we print
# the two commands so the install still completes cleanly.
if [ "$HAS_TTY" = 1 ]; then
  bold "Connect a model  (browser login — choose Codex, Anthropic, or Nous Portal)"
  hermes -p "$PROFILE" model <"$TTY" >"$TTY" 2>&1 || dim "Skipped — run 'ernest model' anytime to connect one."
  bold "Starting Ernest…"
  exec hermes -p "$PROFILE" chat -s ernest-bootstrap <"$TTY" >"$TTY" 2>&1
else
  bold "Ernest is installed. Finish in a terminal:"
  echo "  ernest model                     # connect a model (browser login)"
  echo "  ernest chat -s ernest-bootstrap  # start onboarding"
fi
