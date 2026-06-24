# Use cases — adding and scaling

Ernest's capability is its **installed skill library**. Growing Ernest means installing or authoring skills — never hand-coding features. `ernest-library-index` is the map; `ernest-use-case-author` governs growth.

## Bundled playbooks (work out of the box)

Ernest ships with seven parametrized, draft-first playbooks in `skills/playbooks/`.
They cover the recurring email/CRM/Slack patterns most CEOs hit. You don't install
or configure them — just ask in plain language and Ernest fills the parameters.

| Ask Ernest | Playbook | What it does |
|---|---|---|
| "Add Priya to all my partnership threads" | `loop-in-teammate` | Finds the threads, drafts the loop-in, you approve |
| "Find every B2B sales candidate in my inbox and follow up" | `inbox-prospect-followup` | Builds a vetted list from real exchanges, drafts on-voice follow-ups |
| "Acme — find where I dropped the follow-up" | `account-followup-recovery` | Scans mail + HubSpot for one account, recovers stalled threads/promises |
| "Sync my Korea contacts with Alvin's HubSpot list" | `hubspot-list-reconcile` | Diffs inbox vs a HubSpot list/owner, drafts the CRM updates |
| "Keep the press list in sync with this Google Sheet" | `sheet-contact-sync` | Reconciles a live Google Sheet with mail/HubSpot both ways |
| "Source ex-Skolkovo founders in the US for partnerships" | `contact-sourcing` | Researches new contacts to a brief, drafts first-touch outreach |
| "Turn our Slack into who-owns-what" | `slack-task-tracking` | Extracts commitments from Slack into a tracker, posts transparent status |

The names in these examples are **placeholders** — the playbooks are generic. Any
CEO swaps in their own people, companies, lists, and channels. Everything stays
draft-first: the gate blocks every send, CRM write, and sheet/Slack write until you
approve. When a new pattern repeats often, ask Ernest to turn it into a playbook of
its own (`ernest-use-case-author`).

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
