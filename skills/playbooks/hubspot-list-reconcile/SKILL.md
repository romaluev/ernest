---
name: hubspot-list-reconcile
description: Watch for inbox vs HubSpot list drift (remind). Draft CRM catch-up on-ask. HubSpot writes need approval except hubspot-hygiene mechanical path.
version: 1.1.0
author: Notiky
license: MIT
metadata:
  hermes:
    tags: [ernest, playbook, crm, hubspot, reconcile, watch]
    related_skills: [ernest-watch, sheet-contact-sync, hubspot-hygiene]
---

# Reconcile inbox ↔ HubSpot list

## Parameters
```yaml
segment:         # e.g. "South Korea", "press"
hubspot_target:  # list name OR owner book
window:          # default 12 months mail
fields:          # default stage, owner, last_contacted, notes
```

## Watch half

1. Pull `hubspot_target` membership and inbox contacts for `segment`.
2. Diff: missing in HubSpot, stale fields, gone cold in HubSpot.
3. Reminder card with diff table — **no CRM writes, no drafts**.
4. Write detect-only to `Ernest/CRM/<segment>-drift.md`.

## Draft half

1. Use drift from card or re-diff.
2. Draft HubSpot mutations (create/update/note) as approval batch.
3. Gate blocks every CREATE/UPDATE until CEO approves.

## When NOT to use
External spreadsheet sync (`sheet-contact-sync`). Bulk delete.
