---
name: slack-task-tracking
description: Watch Slack channels for stale/ownerless commitments (remind). Draft tracker updates and digest posts on-ask only.
version: 1.1.0
author: Notiky
license: MIT
metadata:
  hermes:
    tags: [ernest, playbook, slack, tasks, watch]
    related_skills: [ernest-watch, ernest-library-index]
---

# Slack → transparent task tracking

## Parameters
```yaml
channels:
tracker:         # kanban | linear | notion
extract:
owner_rule:
digest:
```

## Watch half

1. Read `channels`. Extract commitments per `extract`.
2. Flag stale, overdue, ownerless items vs tracker state.
3. Reminder card — **no tracker writes, no Slack posts**.

## Draft half

1. Reconcile new/changed tasks; draft tracker creates/updates.
2. Draft `digest` post for channel.
3. Mirror snapshot to `Ernest/Tasks/`. Gate blocks posts and writes until approved.

## When NOT to use
Single ad-hoc task. Private DMs.
