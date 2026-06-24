---
name: slack-task-tracking
description: Use when the CEO wants transparent company task tracking driven from Slack ("turn Slack into who-owns-what"). Watches chosen channels, extracts commitments into a tracker, and posts transparent status. Draft-first for any external post or write.
version: 1.0.0
author: Notiky
license: MIT
metadata:
  hermes:
    tags: [ernest, playbook, slack, tasks, tracking]
    related_skills: [ernest-library-index]
---

# Slack → transparent task tracking

Make ownership visible: pull commitments out of Slack threads into a single
tracker (Hermes kanban, or Linear/Notion via Composio) and keep status honest.

## Parameters
```yaml
channels:        # which Slack channels to watch
tracker:         # kanban (bundled) | linear | notion
extract:         # what counts as a task — default: explicit asks + "I'll/we'll" commitments + @mentions with a verb
owner_rule:      # how to assign — default: the person who committed, else the @mentioned person
digest:          # cadence for a transparency post (default: daily standup summary to the channel)
```

## Steps
1. Read the chosen `channels` (Slack read). Extract candidate tasks per `extract`, with source permalink, owner (`owner_rule`), and due hint.
2. Reconcile against the existing tracker — create only what's new, update status on what moved. Drafts the tracker writes; the gate blocks live creates/updates until approved.
3. Maintain the board in `tracker`; mirror a human-readable snapshot to the vault under `Ernest/Tasks/`.
4. Post a transparent `digest` (who owns what, what's overdue) — draft-first; the Slack post is blocked until the CEO approves the first few, then can be promoted to a cron job.
5. Surface stale/ownerless tasks as ownership cards for the CEO.

## When NOT to use
A single ad-hoc task (just add it). Reading private DMs (out of scope). Auto-posting to channels before the CEO has approved the format.
