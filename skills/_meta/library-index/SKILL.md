---
name: ernest-library-index
description: Use when the CEO asks what Ernest can do, when choosing a use case, or before building a new workflow. Maps each operating need to a vetted, installable skill — Ernest curates, it does not reinvent.
version: 2.0.0
author: Notiky
license: MIT
metadata:
  hermes:
    tags: [ernest, library, skills, use-cases]
    related_skills: [ernest-bootstrap, ernest-use-case-author]
---

# Ernest Library Index

Ernest's capability comes from **installed, vetted skills**, not hand-written ones. Before designing anything, find it here. Install via `scripts/install-skills.sh` or the commands below.

## Playbooks (ship ready — watch + draft halves)

Bundled in `skills/playbooks/`. **Watch half** runs on `ernest-ambient-watch` (remind
only). **Draft half** runs when the CEO asks or taps `draft these` on a card.

| CEO says (example) | Playbook | Watch (cron) |
|---|---|---|
| "Add \<person\> to all \<segment\> threads" | `loop-in-teammate` | missing teammate on segment |
| "Find \<profile\> in mail and follow up" | `inbox-prospect-followup` | new matches, no follow-up |
| "\<Company\> — where I went dark" | `account-followup-recovery` | stalled threads/promises |
| "Sync \<segment\> with \<owner\>'s HubSpot list" | `hubspot-list-reconcile` | inbox vs list drift |
| "Keep \<list\> in sync with this Sheet" | `sheet-contact-sync` | sheet vs mail/CRM drift |
| "Source ex-\<org\> in \<place\>" | `contact-sourcing` | *(on-ask only)* |
| "Slack → who-owns-what" | `slack-task-tracking` | stale/ownerless tasks |
| HubSpot cleanup (symbols, dedupe, translate) | `hubspot-hygiene` | separate Monday cron |

Standing concerns live in `memory/standing-concerns.md` — CEO sets by asking; see `ernest-watch`.

## Operating use cases

| Need | Skill | Install |
|---|---|---|
| Offers, proposals, spreadsheets, decks | docx / pdf / xlsx / pptx | `hermes skills install official/document-skills/<name>` |
| CRM hygiene + pipeline (HubSpot canon) | HubSpot automation | Composio (connected) + `hermes skills install` HubSpot skill |
| Follow-ups, client replies (Outlook) | Outlook automation | Composio + Outlook skill |
| Calendar / scheduling | Outlook Calendar automation | Composio + calendar skill |
| Team coordination + tasks | Slack automation + Linear/Notion + Hermes kanban | Composio + kanban (bundled) |
| Sourcing clients & talent | Lead Research Assistant + browser_use (bundled) | install + `hermes plugins enable browser/browser_use` |
| Daily brief / ambient watch | `ernest-watch` + cron | see `cron/jobs.json` |
| HubSpot mechanical hygiene | `hubspot-hygiene` cron | Mondays 06:00, preview until approved |

## Meta / self-improvement

| Need | Skill |
|---|---|
| Write a new high-quality skill | `skill-creator` (Anthropic official) |
| Optimize existing skills/prompts | Self-Evolution (GEPA + DSPy) |
| Find weak skills & propose fixes | Hermes Dojo |
| Plan without AI slop | Matt Pocock `grill-me` / `to-prd` / `to-issues` |
| Engineering discipline | superpowers (TDD, brainstorming, verification) |

## Selection rules

- Start from a real bottleneck, not a tool.
- Prefer the smallest use case that proves a full loop: signal → context → draft → approval → write-back → outcome.
- If no installed skill fits, propose one through `ernest-use-case-author` (which uses `skill-creator`). Never improvise raw tool calls for a recurring job.
- A new tool needs an owner, approval level, failure mode, and a check before it joins the library.
