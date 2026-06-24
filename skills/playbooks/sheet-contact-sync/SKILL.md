---
name: sheet-contact-sync
description: Watch for drift between a Google Sheet and mail/HubSpot (remind). Draft two-way updates on-ask only.
version: 1.1.0
author: Notiky
license: MIT
metadata:
  hermes:
    tags: [ernest, playbook, googlesheets, reconcile, watch]
    related_skills: [ernest-watch, hubspot-list-reconcile]
---

# Sync a list with a Google Sheet

## Parameters
```yaml
sheet_url:
entity:          # press | partners | candidates | investors
key_column:      # default email
direction:         # sheet_to_crm | crm_to_sheet | two_way
status_columns:
```

## Watch half

1. Read sheet live via Composio — never guess contents.
2. Diff vs mail/HubSpot: missing rows, stale columns, conflicts.
3. Reminder card with diff — **no sheet or CRM writes**.

## Draft half

1. Use diff from card or re-read.
2. Draft updates per `direction` as approval batch.
3. Gate blocks sheet writes and CRM mutations.

## When NOT to use
One-off read. New list with no sheet.
