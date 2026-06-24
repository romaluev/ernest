# Ernest

A CEO operating clone, shipped as a **Hermes profile distribution**. Ernest connects real apps through **Composio**, stores long-term memory in an **Obsidian vault**, drafts in the CEO's voice, and grows by composing vetted, installed skills.

It is a curation and safety layer over [Hermes](https://github.com/NousResearch/hermes-agent) — not a custom app, CRM, or model. Capabilities come from the ecosystem; Ernest decides *which* and enforces *draft-first*: nothing leaves your accounts until you approve it.

## Start

One command installs Hermes (if missing), installs the Ernest profile, connects a model by browser login, and opens onboarding.

**macOS · Linux · WSL · Termux**

```bash
curl -fsSL https://raw.githubusercontent.com/romaluev/ernest/main/setup.sh | bash
```

**Windows (PowerShell)**

```powershell
irm https://raw.githubusercontent.com/romaluev/ernest/main/setup.ps1 | iex
```

The installer is non-interactive: no prompts, no config files to edit, no skills to install by hand. It auto-creates a memory vault (`~/ErnestVault`), runs one model login, then starts onboarding. Two steps require you: logging into a model (Ernest needs one to run) and clicking *authorize* when Ernest hands you an app connect link — nobody can OAuth into your accounts for you.

Zero-touch/fleet: pre-seed `ERNEST_COMPOSIO_API_KEY` and `ERNEST_VAULT`, and the install asks nothing. See [docs/install.md](docs/install.md).

## Where you work

Install and onboarding are a one-time terminal step. After that you work in one of two surfaces:

- **Hermes One desktop app** — chat, read drafts, approve or reject, view memory,
  toggle automations.
- **Slack or Telegram** — message Ernest like a teammate; approvals happen inline.

The CLI (`ernest chat`) is for install/onboarding and power users only. The daily
loop is the same everywhere: **you ask → Ernest drafts → you approve → Ernest
sends**. Nothing leaves your accounts until you approve — the draft-first gate,
enforced in code.

Start here: **[docs/daily-use.md](docs/daily-use.md)**.

## Documentation

| Doc | What it covers |
|---|---|
| [docs/daily-use.md](docs/daily-use.md) | **Start here.** Working with Ernest day to day in the desktop app and Slack |
| [docs/onboarding.md](docs/onboarding.md) | First-run flow: one question, first approved action in about a minute |
| [docs/faq.md](docs/faq.md) | Capabilities, limits, the safety gate, privacy, which interface to use |
| [docs/install.md](docs/install.md) | Prerequisites, install, required keys |
| [docs/configure.md](docs/configure.md) | Hermes setup, Composio, Obsidian, model, desktop, gateway |
| [docs/architecture.md](docs/architecture.md) | How it's built: the gate, memory, what's reused vs. custom |
| [docs/use-cases.md](docs/use-cases.md) | The skill library and how to add or scale use cases |
| [docs/operations.md](docs/operations.md) | Cron, approvals, audit, update, backup |
| [docs/troubleshooting.md](docs/troubleshooting.md) | Common issues and fixes |
| [docs/test-matrix.md](docs/test-matrix.md) | 37 edge cases + 62 CEO scenarios with verification status |

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

Seven bundled, draft-first **playbooks** cover recurring CEO patterns: loop a
teammate into a class of threads, find and follow up with people in your inbox,
recover dropped follow-ups for an account, reconcile mail with a HubSpot list, sync
a list with a Google Sheet, source new contacts to a brief, and turn Slack into
transparent task tracking. They are generic templates — swap in your own people,
companies, and lists. See [docs/use-cases.md](docs/use-cases.md).

## Verify

```bash
bash scripts/verify-ernest.sh
```
