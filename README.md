# Ernest

A CEO operating clone, shipped as a **Hermes profile distribution**. Ernest connects real apps through **Composio**, remembers in an **Obsidian vault**, drafts in the CEO's voice, and self-improves by composing **vetted, installed skills**.

It is a thin curation + safety layer over [Hermes](https://github.com/NousResearch/hermes-agent) — not a custom app, CRM, or model. Capabilities come from the ecosystem; Ernest decides *which* and enforces *draft-first*.

## Start

One command. It installs Hermes (if needed), installs Ernest, connects a model by browser login, and opens onboarding — which handles apps, memory, voice, and skills in the chat.

```bash
curl -fsSL https://raw.githubusercontent.com/romaluev/ernest/main/setup.sh | bash
```

That's the whole setup. No config files to edit, no skills to install by hand. The only thing you can't skip is logging into a model (Ernest needs one to think) and clicking "authorize" on your own apps when Ernest hands you a connect link.

## Documentation

| Doc | What it covers |
|---|---|
| [docs/install.md](docs/install.md) | Prerequisites, install, required keys |
| [docs/configure.md](docs/configure.md) | Hermes setup, Composio, Obsidian, model, desktop, gateway |
| [docs/onboarding.md](docs/onboarding.md) | The CEO first-run flow (interview → connect → first real action) |
| [docs/architecture.md](docs/architecture.md) | How it's built, the gate, memory, what's reused vs. custom |
| [docs/use-cases.md](docs/use-cases.md) | The skill library and how to add / scale use-cases |
| [docs/operations.md](docs/operations.md) | Cron, approvals, audit, update, backup |
| [docs/troubleshooting.md](docs/troubleshooting.md) | Common issues and fixes |
| [docs/test-matrix.md](docs/test-matrix.md) | 37 edge cases + 55 CEO scenarios with verification status |

## Layout

```
setup.sh           one-line installer (Hermes + profile + model + onboarding)
SOUL.md            identity + hard rules (draft-first)
config.yaml        Composio MCP, Obsidian memory, curator, gate, delegation
distribution.yaml  Hermes manifest (requires Composio + Obsidian)
ernest.yaml        scope, approval levels, north-star
cron/jobs.json     daily brief · dropped-ball scan · weekly self-improve
plugins/           ernest-enforcement (the draft-only gate)
skills/_meta/      ernest-bootstrap · library-index · use-case-author
scripts/           install-skills.sh · verify-ernest.sh
memory/            onboarding templates (filled from real data)
```

## Verify

```bash
bash scripts/verify-ernest.sh
```
