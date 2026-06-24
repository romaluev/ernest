# Ernest

A CEO operating clone, shipped as a **Hermes profile distribution**. Ernest connects real apps through **Composio**, remembers in an **Obsidian vault**, drafts in the CEO's voice, and self-improves by composing **vetted, installed skills**.

It is a thin curation + safety layer over [Hermes](https://github.com/NousResearch/hermes-agent) — not a custom app, CRM, or model. Capabilities come from the ecosystem; Ernest decides *which* and enforces *draft-first*.

## 60-second start

```bash
hermes profile install /path/to/ernest --name ernest --alias
# add COMPOSIO_API_KEY, OBSIDIAN_VAULT_PATH, and a model key to the profile .env
ernest setup
bash scripts/install-skills.sh
ernest chat -s ernest-bootstrap
```

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

## Layout

```
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
