---
name: account-followup-recovery
description: Watch for dropped follow-ups on one account or all important contacts (remind). Draft recoveries on-ask only. Default standing concern for "find where I dropped the ball".
version: 1.1.0
author: Notiky
license: MIT
metadata:
  hermes:
    tags: [ernest, playbook, email, crm, followup, watch]
    related_skills: [ernest-watch, inbox-prospect-followup]
---

# Recover dropped follow-ups for one account

## Parameters
```yaml
account:         # company, person, or "*" for all important contacts
staleness:       # default 7 business days without our reply
include:         # threads | deals | promises (default all)
```

## Watch half

1. Resolve `account` (or scan priority contacts if `*`).
2. Find open threads past `staleness`, quiet deals, unfulfilled promises.
3. Ownership cards: contact/thread, owed, days stalled — **no draft messages**.
4. If clean, return clean.

## Draft half

1. Use card items or re-scan.
2. Draft recovery per item in CEO voice from real last exchange.
3. Write `Ernest/Accounts/<account>.md`. Batch for approval.
4. Gate blocks sends and HubSpot writes.

## When NOT to use
Cold prospecting. Use daily brief for general triage summaries.
