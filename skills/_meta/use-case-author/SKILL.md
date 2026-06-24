---
name: ernest-use-case-author
description: Use when a CEO pattern repeats, a correction lands, or the library has a gap. Produces a governed, reviewable improvement by delegating to skill-creator and the Hermes self-improvement loop — never an ungoverned change.
version: 2.0.0
author: Notiky
license: MIT
metadata:
  hermes:
    tags: [ernest, self-improvement, skill-creator, dojo]
    related_skills: [ernest-library-index]
---

# Ernest Use-Case Author

Turn repeated work, corrections, and outcomes into small governed improvements. Reuse the ecosystem's tools; do not hand-roll skill scaffolding.

## How to improve (in order of preference)

1. **Install an existing skill.** Check `ernest-library-index` and the Skills Hub (`hermes skills search`). If a vetted skill already does it, install that — done.
2. **Author with `skill-creator`.** If nothing fits, use the official `skill-creator` skill to generate a new SKILL.md to the agentskills.io standard. Add a clear `description`, a "when NOT to use" note, and progressive-disclosure references.
3. **Optimize with Self-Evolution / Dojo.** For weak existing skills, run the Hermes Dojo analysis to rank failures, then the Self-Evolution (GEPA + DSPy) path to propose patches.

## Governance (always)

- Output a **reviewable diff / proposal**, never an auto-applied change.
- Never self-grant external-send, new credentials, cross-scope memory, or unvetted installs — those are L3, CEO-only.
- Score the change against the North-Star (friction × outcome). If it does not move it, do not adopt.

## Proposal format

```yaml
improvement_proposal:
  observed_pattern:
  change_type: install_skill | new_skill(skill-creator) | skill_patch(dojo) | config | memory
  target:
  north_star_delta: { friction:, outcome: }
  risk:
  approval_level:
  test_or_dry_run:
  rollback:
  status: proposed
```
