# Operations

## Cron automation

`cron/jobs.json` ships four jobs (all disabled on install):

| Job | Schedule | Does |
|---|---|---|
| `ernest-daily-brief` | weekdays 08:00 | Aggregates watch cards + pipeline → morning brief in vault. Remind-only. `[SILENT]` if quiet. |
| `ernest-ambient-watch` | weekdays 11:00 & 16:00 | Runs standing concerns (`memory/standing-concerns.md`). Reminder cards only — **no drafts**. `[SILENT]` if clean. |
| `ernest-hubspot-hygiene` | Mondays 06:00 | CRM mechanical cleanup + propose judgment batch. See [HubSpot hygiene](#hubspot-hygiene). |
| `ernest-self-improve` | Fridays 17:00 | Dojo → one reviewable improvement proposal |

Enable:

```bash
hermes -p ernest cron list
hermes -p ernest cron enable ernest-daily-brief ernest-ambient-watch ernest-hubspot-hygiene
```

Gateway required:

```bash
hermes -p ernest gateway run
hermes -p ernest gateway start
```

Watch jobs set `ERNEST_CRON_JOB` in their prompts so the gate knows context.

## HubSpot hygiene

Config: `ernest.yaml → hygiene_policy`.

| Setting | Default | Meaning |
|---|---|---|
| `dry_run` | `true` | Preview only; no live HubSpot writes |
| `approved` | `false` | CEO/operator must opt in before mechanical auto-apply |
| `mechanical_allowlist` | strip symbols, trim, exact dedupe | Only these auto-apply when approved |
| `mechanical_fields` | company, firstname, lastname, jobtitle | Fields gate allows for auto-apply |
| `propose_only` | translate, status, priority, fuzzy dedupe, deals | Always approval batch |

**First run:** preview written to `Ernest/Hygiene/preview-<date>.md`.

**Opt in:** set `dry_run: false` and `approved: true` in `ernest.yaml` (or ask Ernest to enable after reviewing preview). Mechanical fixes then run on the Monday cron with snapshot + audit. Undo via snapshot restore (proposed batch — CEO approves).

This is the **only** draft-first exception: mechanical field cleanup on HubSpot, bounded by the gate (`plugins/ernest-enforcement`).

## Standing concerns

CEO sets watches by asking; Ernest writes `memory/standing-concerns.md`. No new cron per concern — `ernest-ambient-watch` reads the file each run.

## Approvals

Gate blocks send/publish/write tools. CEO approves in desktop or Slack. Cron external actions default to `cron_mode: deny` in `config.yaml`. Tune levels in `ernest.yaml → approval_defaults`.

## Audit

- Gate: `logs/enforcement-audit.log`
- Hygiene: `logs/hygiene-audit.log`

## Update

```bash
hermes profile update ernest
```

Preserves `.env`, memories, sessions. Distribution-owned files (SOUL, skills, cron) refresh.

## Backup

```bash
hermes profile export ernest
bash scripts/backup-ernest.sh   # VPS: daily cron via vps-production-bootstrap
```

Vault: Obsidian sync or VPS tarball in `~/ernest-backups/`. HubSpot: source of truth for CRM.

## Health checks

```bash
bash scripts/verify-ernest.sh
hermes -p ernest mcp test composio
hermes -p ernest mcp test obsidian
hermes -p ernest skills list
```
