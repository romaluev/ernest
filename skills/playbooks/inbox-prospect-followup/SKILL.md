---
name: inbox-prospect-followup
description: Use when the CEO wants to find everyone in the inbox matching a profile (e.g. "good B2B sales/marketing candidates" or "warm investor intros") and follow up. Builds a vetted list and drafts on-voice follow-ups — never sends without approval.
version: 1.0.0
author: Notiky
license: MIT
metadata:
  hermes:
    tags: [ernest, playbook, email, followup, sourcing]
    related_skills: [inbox-prospect-followup, account-followup-recovery]
---

# Find profile in inbox → follow up

Surface real people from the CEO's mail that match a profile, then prepare
follow-ups in the CEO's voice. Draft-first, real data only.

## Parameters
```yaml
profile:         # who — e.g. "B2B marketing/sales candidates", "press at top-tier outlets"
intent:          # hire | partnership | sales | press | investor
window:          # default: last 6 months
min_signal:      # default: had ≥1 real exchange (not cold lists, not newsletters)
dedupe_against:  # optional: HubSpot list/owner already contacted
```

## Steps
1. Search sent + received mail for people matching `profile` (role/company/keywords). Pull the thread context for each.
2. Score each by `min_signal` — drop newsletters, no-reply, and one-way blasts. Keep real conversations.
3. Build a ranked candidate list (name, last contact, why they match, last thing said). Write it to the vault under `Ernest/Followups/<profile>.md` and show it.
4. If `dedupe_against` is set, remove anyone already active in that HubSpot list/owner.
5. Draft a personalized, on-voice follow-up per person referencing the real last exchange. Batch for approval. Gate blocks sends until approved.

## When NOT to use
Cold outreach to people with no prior thread (that's `contact-sourcing`). A single known follow-up (just draft it).
