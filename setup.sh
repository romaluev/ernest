#!/usr/bin/env bash
#
# Ernest — one-line setup. Fully automated, cold start, any device.
#
#   curl -fsSL https://raw.githubusercontent.com/romaluev/ernest/main/setup.sh | bash
#
# Installs Hermes if missing, installs the Ernest profile, connects a model
# (one browser login — same as Hermes' own setup), then drops you straight into
# onboarding. No prompts, no files to edit. Apps + voice happen in the chat.
#
# Zero-touch / fleet provisioning: pre-seed with env vars and nothing is asked —
#   ERNEST_COMPOSIO_API_KEY=...  ERNEST_VAULT=/path/to/vault  bash setup.sh

set -euo pipefail

REPO="${ERNEST_REPO:-github.com/romaluev/ernest}"
PROFILE="ernest"
TTY=/dev/tty

# A real terminal is reachable iff /dev/tty is usable, even under `curl | bash`
# (stdin is the script then, but /dev/tty still points at the terminal). With no
# tty (CI, ssh -T, MDM, sandboxes) we run hands-off and print the finish steps.
if { true >"$TTY"; } 2>/dev/null && { true <"$TTY"; } 2>/dev/null; then
  HAS_TTY=1
else
  HAS_TTY=0
fi

bold() { printf '\n\033[1m%s\033[0m\n' "$*"; }
dim()  { printf '\033[2m%s\033[0m\n' "$*"; }

command -v git >/dev/null 2>&1 || {
  echo "git is required. Install it first (macOS: xcode-select --install · Debian/Ubuntu: sudo apt install git curl xz-utils)." >&2
  exit 1
}

# 1 — Hermes runtime (skipped if already present; it brings its own Python/Node)
if ! command -v hermes >/dev/null 2>&1; then
  bold "Installing Hermes (one time)…"
  curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash
  export PATH="$HOME/.local/bin:$PATH"
fi
command -v hermes >/dev/null 2>&1 || { echo "Hermes install did not put 'hermes' on PATH. Open a new terminal and re-run." >&2; exit 1; }

# 2 — Ernest profile (identity, config, skills, playbooks, cron — all baked in).
# --force refreshes in place; .env / memories / sessions are preserved.
bold "Installing Ernest…"
if ! hermes profile install "$REPO" --name "$PROFILE" --alias --yes --force; then
  echo "Profile install failed — check network/git access to $REPO and re-run." >&2
  exit 1
fi

# 3 — Memory + optional pre-seeded keys (no prompts; sane defaults).
ENV="${HERMES_HOME:-$HOME/.hermes}/profiles/$PROFILE/.env"
mkdir -p "$(dirname "$ENV")"; touch "$ENV"
put() {  # put KEY VALUE — only if KEY is unset in .env and VALUE is non-empty
  grep -q "^$1=" "$ENV" 2>/dev/null && return 0
  [ -n "${2:-}" ] && printf '%s=%s\n' "$1" "$2" >>"$ENV"
  return 0
}

VAULT="${ERNEST_VAULT:-$HOME/ErnestVault}"
mkdir -p "$VAULT"
put OBSIDIAN_VAULT_PATH "$VAULT"
put COMPOSIO_API_KEY "${ERNEST_COMPOSIO_API_KEY:-}"   # optional; onboarding can do this

# 4 — Model (one browser login) + 5 — onboarding. Both need a terminal; without
# one we finish cleanly and print the two commands.
if [ "$HAS_TTY" = 1 ]; then
  bold "Connect a model  (browser login — Codex, Anthropic, or Nous Portal)"
  hermes -p "$PROFILE" model <"$TTY" >"$TTY" 2>&1 || dim "Skipped — run 'ernest model' anytime."
  bold "Starting Ernest…"
  exec hermes -p "$PROFILE" chat -s ernest-bootstrap <"$TTY" >"$TTY" 2>&1
else
  bold "Ernest is installed. Finish in a terminal:"
  echo "  ernest model                     # connect a model (browser login)"
  echo "  ernest chat -s ernest-bootstrap  # start onboarding"
fi
