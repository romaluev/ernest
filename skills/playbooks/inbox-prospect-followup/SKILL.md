---
name: inbox-prospect-followup
description: Watch for new inbox matches to a saved profile (remind only). Draft on-ask when CEO wants follow-ups prepared. Never sends without approval.
version: 1.1.0
author: Notiky
license: MIT
metadata:
  hermes:
    tags: [ernest, playbook, email, followup, watch]
    related_skills: [ernest-watch, account-followup-recovery]
---

# Find profile in inbox → follow up

## Parameters
```yaml
profile:         # e.g. "B2B marketing/sales candidates"
intent:          # hire | partnership | sales | press | investor
window:          # default 6 months
min_signal:      # default ≥1 real exchange
dedupe_against:  # optional HubSpot list/owner
```

## Watch half

1. Search mail for people matching `profile` with `min_signal`.
2. Flag those with no follow-up from CEO in `staleness` (default 7d since last outbound).
3. Reminder card: ranked list with last exchange summary — **no drafts**.
4. Write detect-only snapshot to `Ernest/Followups/<profile>-watch.md`.

## Draft half

1. Take list from card or re-run search.
2. Dedupe against `dedupe_against` if set.
3. Draft on-voice follow-up per person referencing last exchange.
4. Batch for approval. Gate blocks sends.

## When NOT to use
Cold outreach with no prior thread (`contact-sourcing`).
