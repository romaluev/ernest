---
name: ernest-watch
description: Use on the ambient-watch cron and when loading standing concerns. Runs each enabled concern's watch-half (detect + remind only). Writes reminder cards with one-tap draft triggers. Never drafts email, CRM, or sheet content in watch mode.
version: 1.1.0
author: Notiky
license: MIT
metadata:
  hermes:
    tags: [ernest, watch, cron, ambient]
    related_skills: [ernest-bootstrap, ernest-library-index]
---

# Ernest watch engine

Config-driven ambient monitoring. Reads `memory/standing-concerns.md` and
`ernest.yaml → watchers`. Each concern invokes a playbook's **watch-half** only.

## Rules (non-negotiable)

- **Remind only.** No email drafts, no CRM writes, no sheet edits, no chat posts with draft content.
- If a concern is clean, skip it (contribute to `[SILENT]` when all are clean).
- Real data only; skip concerns whose apps are not connected.

## Run sequence

1. Parse `memory/standing-concerns.md` for enabled `concerns:` entries.
2. For each concern, load the named playbook and run its **Watch half** section.
3. Write one reminder card per non-empty result to `watchers.card_dir` (default
   `Ernest/00-Watch/<concern-id>-<date>.md`).
4. Optionally mirror summaries to the CEO's chat (Telegram or Slack) if a gateway
   is configured — reminder text only, no drafts.

## Reminder card format

Every card MUST include:

```yaml
reminder_card:
  id: "<concern-id>"
  playbook: "<playbook-name>"
  detected_at: "<iso>"
  summary: "<one line>"
  items: []          # contacts, threads, rows — with source refs
  suggested_next: "<what draft-half would do>"
  draft_trigger: "draft these"   # CEO says this (or taps) to invoke draft-half
  draft_params: {}    # pass through to playbook draft-half
```

In Telegram or Slack: post the summary + "Reply **draft these** to have Ernest prepare actions."
In desktop: present the card with a **Draft these** action that sends the trigger phrase.

## Adding concerns

CEO asks ("watch partnership threads for missing Dana", "alert when Korea list
drifts from mail"). Ernest updates `standing-concerns.md` — no new cron job.

## Playbook watch halves

| Playbook | Watch detects |
|---|---|
| `loop-in-teammate` | Segment threads missing configured teammate |
| `inbox-prospect-followup` | New inbox matches to saved profile (no follow-up yet) |
| `account-followup-recovery` | Stalled threads / unmet promises per account or `*` |
| `hubspot-list-reconcile` | Inbox vs HubSpot list drift |
| `sheet-contact-sync` | Sheet vs mail/CRM drift |
| `slack-task-tracking` | Stale or ownerless commitments in watched channels |
| `contact-sourcing` | *(no watch half — on-ask only)* |
| `hubspot-hygiene` | *(separate cron — not via ambient-watch)* |

When the CEO sends `draft_trigger` with a card id, run that playbook's **Draft half**.
