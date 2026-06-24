# Operations

## Cron automation

`cron/jobs.json` ships three jobs (disabled on install — Hermes never auto-schedules distribution cron):

| Job | Schedule | Does |
|---|---|---|
| `ernest-daily-brief` | weekdays 08:00 | Morning brief to the Obsidian vault; quiet if nothing |
| `ernest-dropped-ball-scan` | weekdays 11:00 & 16:00 | Stalled threads / unmet promises → ownership cards; drafts only |
| `ernest-self-improve` | Fridays 17:00 | Hermes Dojo ranks weak skills → one reviewable improvement |

Review and enable:

```bash
hermes -p ernest cron list
hermes -p ernest cron enable ernest-daily-brief
```

Cron requires the gateway/scheduler running:

```bash
hermes -p ernest gateway run     # foreground (WSL/Docker)
hermes -p ernest gateway start   # background service (systemd/launchd)
```

All ambient jobs are draft-only and reply `[SILENT]` when there's nothing to report, so they don't pay tokens or spam on quiet days.

## Approvals

External actions pause for the CEO. The `ernest-enforcement` gate blocks send/publish/write tools; the CEO approves in chat or desktop. Tune levels in `ernest.yaml → approval_defaults`. Cron runs default to `cron_mode: deny` for external actions — they draft and wait.

## Audit

The gate logs blocked/approved external actions under the profile's `logs/`. Pair with the [Labyrinth observability](https://github.com/ali-erfan-dev/awesome-hermes-usecases/blob/main/usecases/hermes-labyrinth-observability.md) dashboard for a full view of prompts, tool calls, approvals, and cron runs.

## Update

```bash
hermes profile update ernest
```

Replaces distribution-owned files (SOUL, skills, cron, config schema). **Preserves** `.env`, memories, sessions, and your `config.yaml` tweaks. Pass `--force-config` only to reset config to the distribution default.

## Backup

```bash
hermes profile export ernest      # local backup of the whole profile
```

The Obsidian vault is backed up by Obsidian's own sync. HubSpot remains the source of truth for contacts/pipeline.

## Health checks

```bash
bash scripts/verify-ernest.sh          # structure + gate
hermes -p ernest mcp test composio     # connectors live
hermes -p ernest mcp test obsidian     # memory reachable
hermes -p ernest skills list           # library present
```
