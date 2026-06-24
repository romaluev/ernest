---
name: hubspot-hygiene
description: Use on the HubSpot hygiene cron or when the CEO asks to clean CRM data. Auto-applies only mechanical fixes (strip junk symbols, trim, exact dedupe) when hygiene_policy is approved and dry_run is false. Proposes translations, status, priority, and fuzzy dedupe for approval. Snapshots before any live write.
version: 1.0.0
author: Notiky
license: MIT
metadata:
  hermes:
    tags: [ernest, playbook, crm, hubspot, hygiene, cron]
    related_skills: [ernest-bootstrap, hubspot-list-reconcile]
---

# HubSpot hygiene

Replaces manual CRM cleanup (translate company names, fill status/priority, strip
junk symbols, dedupe). Read `ernest.yaml → hygiene_policy` before every run.

## Modes

| Mode | When | Behavior |
|---|---|---|
| **preview** | `dry_run: true` OR `approved: false` (default) | Scan HubSpot, write preview to vault, apply nothing |
| **auto-mechanical** | `dry_run: false` AND `approved: true` | Auto-apply allowlisted mechanical fixes only |
| **propose** | always | Judgment calls → reviewable batch for CEO approval |

## Mechanical allowlist (auto-apply when policy permits)

- `strip_junk_symbols` — remove `*`, `#`, stray punctuation from name/company fields
- `trim_whitespace` — leading/trailing space, collapse double spaces
- `exact_dedupe` — merge records with identical email (never fuzzy without approval)

Fields in scope: `company`, `firstname`, `lastname`, `jobtitle` (per `mechanical_fields`).

## Propose-only (never auto-apply)

- `translate_company_names` — non-Latin or mixed script → consistent English/Latin form
- `infer_status` / `infer_priority` — from mail threads and deal activity
- `fuzzy_dedupe` — similar names/companies
- `create_deals` — warm contacts → deals (Asian market priority, etc.)

## Run sequence (cron or on-ask)

1. Read `hygiene_policy` from `ernest.yaml`. If preview mode, say so in the output header.
2. List HubSpot contacts/deals in scope (recent imports, list membership, or all if unspecified).
3. Classify each issue: mechanical vs propose-only.
4. **Before any live write:** write snapshot JSON to `snapshot_dir` and set
   `logs/hygiene-active-run.json`:
   ```yaml
   run_id: "<iso-timestamp>"
   job_id: ernest-hubspot-hygiene
   mechanical_only: true
   started_at: "<iso>"
   ```
   Append actions to `audit_log`.
5. **Preview mode:** write `Ernest/Hygiene/preview-<date>.md` with proposed mechanical +
   judgment batches. Do not call HubSpot UPDATE.
6. **Auto-mechanical mode:** apply only allowlisted transforms on allowlisted fields via
   `HUBSPOT_UPDATE_CONTACT`. Gate permits these only while the active-run marker exists.
7. **Propose batch:** write `Ernest/Hygiene/proposed-<date>.md` for CEO approval in chat.
8. Clear `hygiene-active-run.json` when the run finishes (success or error).

## Undo

Keep the latest snapshot at `Ernest/Hygiene/snapshots/latest.json`. On "undo last hygiene
run", restore field values from that snapshot via a proposed batch (CEO approves each
restore — undo is not silent auto-write).

## When NOT to use

Bulk delete, merge without snapshot, or auto-create deals without approval.
