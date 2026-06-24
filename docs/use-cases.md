# Use cases — adding and scaling

Ernest's capability is its **installed skill library**. Growing Ernest means installing or authoring skills — never hand-coding features. `ernest-library-index` is the map; `ernest-use-case-author` governs growth.

## Bundled playbooks (watch + draft)

Eight playbooks in `skills/playbooks/`. Each has a **watch half** (cron reminds) and
a **draft half** (on your ask or **`draft these`** on a card). `contact-sourcing` is draft-only.

| Pattern | Playbook | Watch reminds | Draft prepares |
|---|---|---|---|
| Loop teammate into segment threads | `loop-in-teammate` | Missing CC | Loop-in drafts |
| Profile in inbox, no follow-up | `inbox-prospect-followup` | Stale matches | Follow-up drafts |
| Dropped ball on account | `account-followup-recovery` | Stalled threads | Recovery drafts |
| Inbox vs HubSpot list | `hubspot-list-reconcile` | Drift | CRM update batch |
| Sheet vs mail/CRM | `sheet-contact-sync` | Row drift | Sheet/CRM batch |
| New contacts to brief | `contact-sourcing` | — | First-touch drafts |
| Slack commitments | `slack-task-tracking` | Stale tasks | Tracker + digest |
| HubSpot cleanup | `hubspot-hygiene` | Monday cron | Preview / mechanical / propose |

Standing watches: `memory/standing-concerns.md`. CEO sets by asking — no YAML editing.

Draft-first: gate blocks sends and CRM/sheet writes until approval. **Exception:** mechanical HubSpot hygiene when `hygiene_policy.approved: true` ([operations.md](operations.md#hubspot-hygiene)).

## The library

| Need | Skill | Source |
|---|---|---|
| Offers, proposals, sheets, decks | docx / pdf / xlsx / pptx | Anthropic (official) |
| Write new skills | `skill-creator` | Anthropic (official) |
| CRM, email, calendar, Slack | HubSpot / Outlook / Slack tools | Composio MCP |
| Sourcing | Lead Research + `browser_use` | community + bundled |
| Self-improvement | Hermes Dojo + Self-Evolution | vetted community |
| Planning (anti-slop) | Matt Pocock grill-me / to-prd / to-issues | vetted community |
| Engineering discipline | superpowers | installed |

Install the curated set:

```bash
bash scripts/install-skills.sh
```

Official skills install automatically; community ones are printed for review (trust policy: official auto, community case-by-case).

## Find and install a skill

```bash
hermes -p ernest skills search <topic>        # search the Skills Hub
hermes -p ernest skills inspect <identifier>   # preview before install
hermes -p ernest skills install <identifier>   # install
```

Sources the Hub supports: official, GitHub repos, skills.sh (`npx skills add`), URLs.

## Add a new use case (the right order)

1. **Reuse.** Search the Hub. If a vetted skill exists, install it — done.
2. **Author.** If nothing fits, use `skill-creator` to generate a `SKILL.md` to the agentskills.io standard (clear `description`, a "when NOT to use" note, references for progressive disclosure).
3. **Improve.** For weak existing skills, run Hermes Dojo to rank failures, then Self-Evolution to propose patches.

Ask Ernest directly:

```text
We keep writing short offer summaries by hand. Propose a reusable use case.
```

Ernest replies via `ernest-use-case-author` with a governed proposal:

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

## Governance

- Every change is a **reviewable proposal**, never auto-applied.
- Ernest cannot self-grant external send, new credentials, cross-scope memory, or unvetted installs (L3, CEO-only).
- A change that doesn't move the North-Star (friction × outcome) isn't adopted.

## Scaling

- **More apps:** authorize them in Composio — no config change.
- **More skills:** install from the Hub or author with `skill-creator`.
- **Continuous growth:** the weekly self-improve cron (see [operations.md](operations.md)) runs Dojo to propose one improvement per week, CEO-approved.
- **More surfaces:** add a Hermes gateway (Slack, Telegram) — same profile, same skills.
