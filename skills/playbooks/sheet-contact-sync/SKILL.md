---
name: sheet-contact-sync
description: Use when the CEO wants a list (press, partners, candidates) kept in sync with a Google Sheet (e.g. "sync the press list incl TechCrunch with <sheet URL>"). Reconciles a sheet against mail/HubSpot, surfaces diffs, and drafts both-side updates. Draft-first.
version: 1.0.0
author: Notiky
license: MIT
metadata:
  hermes:
    tags: [ernest, playbook, googlesheets, reconcile, press]
    related_skills: [hubspot-list-reconcile]
---

# Sync a list with a Google Sheet

Keep an external Google Sheet and Ernest's view (mail + HubSpot) consistent —
e.g. a press list with named contacts. Reads the sheet live via Composio.

## Parameters
```yaml
sheet_url:       # the Google Sheet (and tab/gid if given)
entity:          # press | partners | candidates | investors
key_column:      # how to match rows — default: email, fallback name+outlet
direction:       # sheet_to_crm | crm_to_sheet | two_way (default: two_way)
status_columns:  # columns Ernest may propose to fill (e.g. last_contact, status, owner)
```

## Steps
1. Read the sheet (GOOGLESHEETS read) — never guess its contents. Map columns to fields via `key_column`.
2. Pull the matching mail threads / HubSpot records for those rows.
3. Diff per row: missing in sheet, missing in CRM/mail, stale `status_columns`, conflicting values.
4. Write the reconciliation to `Ernest/Lists/<entity>.md` and show the diff table.
5. Draft updates for the chosen `direction` — sheet cell writes and/or HubSpot updates — as one approval batch. The gate blocks every sheet write and CRM mutation until approved.

## When NOT to use
A one-off lookup in a sheet (just read it). Building a new list from scratch with no sheet (use `inbox-prospect-followup` or `contact-sourcing`).
