# Install

## Prerequisites

- [Hermes Agent](https://github.com/NousResearch/hermes-agent) ≥ 0.12.0 (`hermes --version`)
- Python 3.11+ and `git`
- Node / `npx` (for the Composio and Obsidian MCP servers)
- A [Composio](https://app.composio.dev) account (free tier works)
- An Obsidian vault (any folder Obsidian manages)
- One model key: OpenRouter, Anthropic, or OpenAI

## Install the distribution

```bash
hermes profile install /path/to/ai-first-company/ernest --name ernest --alias
```

This copies the distribution into `~/.hermes/profiles/ernest/`, writes a `.env.EXAMPLE`, and creates the `ernest` command alias. Cron jobs ship disabled until you enable them (see [operations](operations.md)).

From a git remote instead of a local path:

```bash
hermes profile install github.com/<org>/ernest --name ernest --alias
```

## Required keys

Copy the example env and fill it in:

```bash
cp ~/.hermes/profiles/ernest/.env.EXAMPLE ~/.hermes/profiles/ernest/.env
```

| Key | Required | Purpose |
|---|---|---|
| `COMPOSIO_API_KEY` | yes | Connects HubSpot, Outlook, Calendar, Slack, Gmail |
| `OBSIDIAN_VAULT_PATH` | yes | Absolute path to the CEO's Obsidian vault (long-term memory) |
| `OPENROUTER_API_KEY` / `ANTHROPIC_API_KEY` / `OPENAI_API_KEY` | one of | Model access |

Keys already exported in your shell are detected during install and don't need duplicating.

## Verify

```bash
bash /path/to/ernest/scripts/verify-ernest.sh
hermes -p ernest skills list      # ernest-bootstrap, library-index, use-case-author
hermes -p ernest cron list        # 3 jobs, disabled until enabled
```

Next: [configure.md](configure.md).
