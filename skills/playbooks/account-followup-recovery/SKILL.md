---
name: account-followup-recovery
description: Use when the CEO names one account/company/relationship and wants every dropped follow-up recovered (e.g. "<Company> follow up — find where I went dark"). Scans email + HubSpot for that account, finds stalled threads and unmet promises, drafts recoveries. Draft-first.
version: 1.0.0
author: Notiky
license: MIT
metadata:
  hermes:
    tags: [ernest, playbook, email, crm, followup]
    related_skills: [inbox-prospect-followup]
---

# Recover dropped follow-ups for one account

A focused dropped-ball scan scoped to a single company/relationship across mail
and CRM. Finds where the CEO went dark or made a promise and never closed it.

## Parameters
```yaml
account:         # company or person — resolve to domains + HubSpot company/contacts
staleness:       # default: no reply from us in 7+ business days on an open thread
include:         # threads | deals | promises (default: all three)
```

## Steps
1. Resolve `account` to email domains and the HubSpot company + associated contacts/deals.
2. Pull open threads (no reply from us past `staleness`), open deals with no recent activity, and explicit promises ("I'll send…", "let me check…") that were never fulfilled.
3. Produce prioritized ownership cards: contact/thread, what's owed, how long stalled, suggested next step.
4. Draft the recovery message per item, in the CEO's voice, referencing the real last exchange. Batch for approval.
5. Write the recovered list to `Ernest/Accounts/<account>.md`. Gate blocks sends and any HubSpot write until approved.

## When NOT to use
Account-wide cold prospecting (use `contact-sourcing`). General inbox triage (that's the daily brief / dropped-ball cron).
