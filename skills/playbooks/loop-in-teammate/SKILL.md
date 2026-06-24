---
name: loop-in-teammate
description: Watch (cron) or draft (on-ask) when a teammate should be on every thread of a segment but the CEO keeps dropping loop-ins. Watch reminds; draft-half prepares loop-ins after CEO says "draft these".
version: 1.1.0
author: Notiky
license: MIT
metadata:
  hermes:
    tags: [ernest, playbook, email, delegation, watch]
    related_skills: [ernest-watch, ernest-bootstrap, ernest-library-index]
---

# Loop in a teammate

## Parameters
```yaml
teammate:        # who to add (name → email via HubSpot/Outlook)
segment:         # e.g. "B2B", "partnerships"
channel:         # email | slack (default email)
window:          # default 90d open threads
mode:            # cc_going_forward | forward_context | both
```

## Watch half (cron / ambient-watch only)

1. Resolve `teammate` to address/handle.
2. Find open threads matching `segment` in `window` where `teammate` is **not** on the thread.
3. Output a reminder card — no drafts, no CC, no sends.
4. If none missing, return clean.

## Draft half (CEO asks or replies "draft these")

1. Use items from the reminder card or re-scan with same params.
2. Draft loop-in per thread (CC + one-line context in CEO voice, or forward).
3. Batch for approval. Gate blocks sends until approved.
4. Log to `Ernest/Delegation/` on approval.

## When NOT to use
One-off CC. Bulk without a clear segment.
