---
name: contact-sourcing
description: Use when the CEO wants NEW contacts sourced to a brief (e.g. "find ex-<org> people in <place> for partnership/hire", or "people like <LinkedIn URL>"). Uses web/LinkedIn research to build an enriched, deduped target list and drafts first-touch outreach. Draft-first.
version: 1.0.0
author: Notiky
license: MIT
metadata:
  hermes:
    tags: [ernest, playbook, sourcing, research, browser]
    related_skills: [inbox-prospect-followup, hubspot-list-reconcile]
---

# Source new contacts to a brief

Find people the CEO doesn't already know, matching a profile, for partnership or
hiring. Reuses web search + the `browser_use` plugin and/or Composio LinkedIn —
this skill orchestrates them, it does not scrape on its own.

## Parameters
```yaml
brief:           # who — e.g. "ex-Skolkovo founders now in the USA", "people like <LinkedIn URL>"
goal:            # partnership | hire | sales | investor
count:           # how many to surface (default: 15)
source:          # linkedin | web | both (default: both)
exclude:         # optional: already in HubSpot / already emailed
```

## Steps
1. Turn `brief` into concrete search criteria (org, role, geography, signals). If a LinkedIn URL is given, derive the pattern from that profile.
2. Source candidates via web search / `browser_use` / Composio LinkedIn. Capture name, role, company, link, and the evidence they match.
3. Dedupe against `exclude` (HubSpot + prior mail) so the CEO never re-contacts someone.
4. Write the enriched list to `Ernest/Sourcing/<goal>.md` and show it ranked, with the match evidence — flag anything low-confidence rather than inventing it.
5. Draft a first-touch message per person, tailored to the evidence, in the CEO's voice. Batch for approval. Gate blocks sends.

## When NOT to use
Following up with people already in the inbox (use `inbox-prospect-followup`). Any source that needs a login the CEO hasn't connected — say so, don't fake results.
