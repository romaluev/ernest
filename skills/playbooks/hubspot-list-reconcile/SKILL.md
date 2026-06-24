---
name: hubspot-list-reconcile
description: Use when the CEO wants email contacts reconciled with a HubSpot list or owner's book (e.g. "sync my <region> email with <owner>'s HubSpot list"). Finds who's in mail but missing/stale in HubSpot and drafts the CRM updates. Draft-first — HubSpot writes need approval.
version: 1.0.0
author: Notiky
license: MIT
metadata:
  hermes:
    tags: [ernest, playbook, crm, hubspot, reconcile]
    related_skills: [account-followup-recovery, sheet-contact-sync]
---

# Reconcile inbox ↔ HubSpot list

HubSpot is the source of truth, but the CEO's inbox runs ahead of it. This finds
the gap for a segment and prepares the CRM to catch up. Nothing writes to HubSpot
without approval.

## Parameters
```yaml
segment:         # which contacts — e.g. "South Korea", "press", a deal stage
hubspot_target:  # a HubSpot list name OR an owner whose book to reconcile against
window:          # default: last 12 months of mail
fields:          # which fields to set/update (default: stage, owner, last_contacted, notes)
```

## Steps
1. Pull the `hubspot_target` membership (list or owner's contacts) via HubSpot.
2. Pull inbox contacts matching `segment` with real exchanges.
3. Diff: (a) in mail, missing from HubSpot; (b) in both but stale (last_contacted/stage out of date); (c) in HubSpot, gone cold.
4. Present the diff as a table and write it to `Ernest/CRM/<segment>-reconcile.md`.
5. Draft the HubSpot mutations (create contact, update stage/owner/last_contacted, add note) as an approval batch. The gate blocks every CREATE/UPDATE until the CEO approves.

## When NOT to use
Syncing against an external spreadsheet (use `sheet-contact-sync`). Bulk deleting CRM records (out of scope — propose via use-case-author).
