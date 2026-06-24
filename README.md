# Ernest

A CEO operating clone, shipped as a **Hermes profile distribution**. Ernest connects real apps through **Composio**, remembers in an **Obsidian vault**, drafts in the CEO's voice, and self-improves by composing **vetted, installed skills**.

It is a thin curation + safety layer over [Hermes](https://github.com/NousResearch/hermes-agent) — not a custom app, CRM, or model. Capabilities come from the ecosystem; Ernest decides *which* and enforces *draft-first*.

## Start

One command. It installs Hermes (if needed), installs Ernest, connects a model by browser login, and opens onboarding — which handles apps, memory, voice, and skills in the chat.

**macOS · Linux · WSL · Termux**

```bash
curl -fsSL https://raw.githubusercontent.com/romaluev/ernest/main/setup.sh | bash
```

**Windows (PowerShell)**

```powershell
irm https://raw.githubusercontent.com/romaluev/ernest/main/setup.ps1 | iex
```

That's the whole setup — no prompts, no config files to edit, no skills to install by hand. The installer is non-interactive: it auto-creates a memory vault and goes straight to one model login, then onboarding. The only things you can't skip are logging into a model (Ernest needs one to think) and clicking "authorize" on your own apps when Ernest hands you a connect link — nobody can OAuth into your accounts for you.

Fleet/zero-touch: pre-seed `ERNEST_COMPOSIO_API_KEY` and `ERNEST_VAULT` and the install asks nothing at all.

## Where you work

Install and onboarding are a one-time terminal moment. After that you never touch
the terminal — you live in one of two places:

- **Hermes One desktop app** — your main surface: chat, read drafts, approve or
  reject, see memory, toggle automations.
- **Slack or Telegram** — Ernest as an always-on teammate you just message;
  approvals happen inline.

The CLI (`ernest chat`) is only for install/onboarding and power users. Everything
that matters day to day is the same simple loop: **you ask → Ernest drafts → you
approve → Ernest sends**. Nothing leaves your accounts until you approve it —
that's the draft-first gate, and it can't be skipped by accident.

Start here: **[docs/daily-use.md](docs/daily-use.md)**.

## Documentation

| Doc | What it covers |
|---|---|
| [docs/daily-use.md](docs/daily-use.md) | **Start here.** How a CEO works with Ernest every day in the desktop app and Slack |
| [docs/onboarding.md](docs/onboarding.md) | The CEO first-run flow — one question, first real action in ~a minute |
| [docs/faq.md](docs/faq.md) | What it can/can't do, the safety gate, privacy, which interface to use |
| [docs/install.md](docs/install.md) | Prerequisites, install, required keys |
| [docs/configure.md](docs/configure.md) | Hermes setup, Composio, Obsidian, model, desktop, gateway |
| [docs/architecture.md](docs/architecture.md) | How it's built, the gate, memory, what's reused vs. custom |
| [docs/use-cases.md](docs/use-cases.md) | The skill library and how to add / scale use-cases |
| [docs/operations.md](docs/operations.md) | Cron, approvals, audit, update, backup |
| [docs/troubleshooting.md](docs/troubleshooting.md) | Common issues and fixes |
| [docs/test-matrix.md](docs/test-matrix.md) | 37 edge cases + 62 CEO scenarios (incl. the named asks) with verification status |

## Layout

```
setup.sh           one-line installer — macOS/Linux/WSL/Termux
setup.ps1          one-line installer — Windows (PowerShell)
SOUL.md            identity + hard rules (draft-first)
config.yaml        Composio MCP, Obsidian memory, curator, gate, delegation
distribution.yaml  Hermes manifest (requires Composio + Obsidian)
ernest.yaml        scope, approval levels, north-star
cron/jobs.json     daily brief · dropped-ball scan · weekly self-improve
plugins/           ernest-enforcement (the draft-only gate)
skills/_meta/      ernest-bootstrap · library-index · use-case-author
skills/playbooks/  7 ready-to-use, parametrized CEO workflows (email/CRM/Slack)
scripts/           install-skills.sh · verify-ernest.sh
memory/            onboarding templates (filled from real data)
```

## What it does out of the box

Seven bundled, draft-first **playbooks** cover the recurring CEO patterns — loop a
teammate into a class of threads, find & follow up with people in your inbox,
recover dropped follow-ups for an account, reconcile mail with a HubSpot list, sync
a list with a Google Sheet, source new contacts to a brief, and turn Slack into
transparent task tracking. They're generic templates — any CEO swaps in their own
people, companies, and lists. See [docs/use-cases.md](docs/use-cases.md).

## Verify

```bash
bash scripts/verify-ernest.sh
```
