# Architecture

Ernest is a **Hermes profile distribution** — a packaged agent installed with `hermes profile install`. It owns identity, safety, and curation. Everything else is reused.

## Layers

```
CEO ──> Hermes One desktop / CLI / Slack gateway
          │
          ▼
       Ernest profile
          ├─ SOUL.md ............ identity + hard rules (draft-first)
          ├─ ernest-enforcement . the gate (blocks send/publish until approved)
          ├─ skills/_meta ....... bootstrap · library-index · use-case-author
          ├─ cron/jobs.json ..... ambient automation
          └─ memory ............. Obsidian vault (long-term) + Hermes memory
          │
          ▼  MCP
   Composio ──> HubSpot · Outlook · Calendar · Slack · Gmail · 500+ apps
```

## What is custom vs. reused

| Custom (only what must be) | Reused (the ecosystem) |
|---|---|
| `SOUL.md` — CEO-clone identity | Hermes runtime, profiles, cron, curator, gateway |
| `ernest-enforcement` — draft-only gate | Composio MCP — all app connectors |
| `ernest-bootstrap` — onboarding | Obsidian — memory |
| `ernest-library-index` — curation map | Anthropic skills — docx/pdf/xlsx/pptx, skill-creator |
| `ernest-use-case-author` — governed growth | Hermes Dojo + Self-Evolution — self-improvement |
| | Matt Pocock skills — anti-slop planning |
| | superpowers — engineering discipline |

If a capability isn't in the left column, Ernest does **not** hand-build it — it installs or composes the right column.

## The gate

`plugins/ernest-enforcement` registers a `pre_tool_call` hook that:

- **Blocks** external send/publish/write tools (e.g. `outlook_send_email`, HubSpot writes, Slack post) until the CEO approves.
- **Allows** drafts, reads, and internal writes.
- **Enforces scope** from `ernest.yaml` (`scope.read/write/deny`).

Approval levels (`ernest.yaml → approval_defaults`):

| Level | Examples |
|---|---|
| L0 | reads, summaries, draft tasks |
| L1 | reversible internal updates (notify) |
| L2 | external drafts, HubSpot stage changes, outreach — **CEO approves** |
| L3 | money, legal, deletes, permission changes — **manual only** |

## Memory

- **Long-term:** Obsidian vault (`Ernest/`) — human-readable, CEO-inspectable.
- **Working:** Hermes native memory (`MEMORY.md` / `USER.md`) with curator promotion/decay.
- **Truth for contacts/pipeline:** HubSpot (via Composio), not a local store.

## Token discipline

Skills load progressively (name + description ≈ 100 tokens; body on demand). `ernest.yaml → token_budgets` caps per-turn context. This is native skill behavior, not custom code.

Next: [use-cases.md](use-cases.md).
