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

## Playbooks (ship ready-to-use, parametrized)

These are bundled in `skills/playbooks/` — no install needed. Each is a draft-first,
parametrized workflow over the connected tools. Match the CEO's ask to a playbook,
fill its parameters from the request, and run it. They are templates, not hardcoded
to any one person or company — any CEO scales by reusing them with new parameters.

| CEO says (example) | Playbook |
|---|---|
| "Add <person> to all <segment> threads" | `loop-in-teammate` |
| "Find all <profile> in my mail and follow up" | `inbox-prospect-followup` |
| "<Company> follow-up — find where I went dark" | `account-followup-recovery` |
| "Sync my <segment> email with <owner>'s HubSpot list" | `hubspot-list-reconcile` |
| "Keep <list> in sync with this Google Sheet <url>" | `sheet-contact-sync` |
| "Source ex-<org> people in <place> for partnership/hire" | `contact-sourcing` |
| "Make transparent task tracking from Slack" | `slack-task-tracking` |

If a request almost fits a playbook, run it with adjusted parameters. If a new
pattern repeats, promote it via `ernest-use-case-author` (don't improvise raw calls).

## Operating use cases

| Need | Skill | Install |
|---|---|---|
| Offers, proposals, spreadsheets, decks | docx / pdf / xlsx / pptx | `hermes skills install official/document-skills/<name>` |
| CRM hygiene + pipeline (HubSpot canon) | HubSpot automation | Composio (connected) + `hermes skills install` HubSpot skill |
| Follow-ups, client replies (Outlook) | Outlook automation | Composio + Outlook skill |
| Calendar / scheduling | Outlook Calendar automation | Composio + calendar skill |
| Team coordination + tasks | Slack automation + Linear/Notion + Hermes kanban | Composio + kanban (bundled) |
| Sourcing clients & talent | Lead Research Assistant + browser_use (bundled) | install + `hermes plugins enable browser/browser_use` |
| Daily brief / ambient watch | Daily Briefing pattern + zero-token cron | see `cron/jobs.json` |

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
