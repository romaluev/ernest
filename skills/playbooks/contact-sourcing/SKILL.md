---
name: contact-sourcing
description: On-ask only (no watch half). Source NEW contacts to a brief via web/LinkedIn; draft first-touch outreach. Never sends without approval.
version: 1.1.0
author: Notiky
license: MIT
metadata:
  hermes:
    tags: [ernest, playbook, sourcing, research]
    related_skills: [inbox-prospect-followup]
---

# Source new contacts to a brief

Research push — not a standing watch. CEO asks; Ernest runs draft-half only.

## Parameters
```yaml
brief:
goal:            # partnership | hire | sales | investor
count:           # default 15
source:          # linkedin | web | both
exclude:
```

## Draft half (only mode)

1. Turn `brief` into search criteria.
2. Source via web / `browser_use` / Composio LinkedIn with evidence.
3. Dedupe against `exclude`.
4. Write `Ernest/Sourcing/<goal>.md`.
5. Draft first-touch per person. Batch for approval.

## When NOT to use
Inbox follow-ups (`inbox-prospect-followup`). Unconnected login required — say so.
