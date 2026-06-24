---
name: loop-in-teammate
description: Use when the CEO wants a teammate added to a whole class of threads/deals (e.g. "add <person> to all <segment> threads") because the CEO keeps dropping that ball. Finds matching threads and drafts the loop-in — never sends without approval.
version: 1.0.0
author: Notiky
license: MIT
metadata:
  hermes:
    tags: [ernest, playbook, email, delegation]
    related_skills: [ernest-bootstrap, ernest-library-index]
---

# Loop in a teammate

The CEO's intros/handoffs slip; a named teammate should be on every thread of a
given type. This finds those threads and prepares the loop-in. Draft-first.

## Parameters (ask only what's missing)
```yaml
teammate:        # who to add (name → resolve to email via HubSpot/Outlook contacts)
segment:         # which threads — e.g. "B2B", "partnerships", "deals > $X", a label
channel:         # email (CC/forward) | slack (add to channel/thread)
window:          # default: open threads in the last 90 days
mode:            # cc_going_forward | forward_context | both
```

## Steps
1. Resolve `teammate` to a real address/handle (Outlook contacts or HubSpot). If ambiguous, ask.
2. Find threads matching `segment` via search (Gmail/Outlook search, HubSpot deal threads). Show the matched set as a list for confirmation — do not act on a guess.
3. For each thread, draft the loop-in (CC + a one-line context note in the CEO's voice, or a forward). Group into one approval batch.
4. Present an approval batch: thread → action → draft. The CEO approves; the gate blocks any send until then.
5. On approval, the teammate is added going forward; log what was looped in to the vault under `Ernest/Delegation/`.

## When NOT to use
One-off CC (just draft the single reply). Bulk sends without a clear segment (too risky — narrow it first).
