# Daily use

Install is a one-time terminal moment. After that you never touch the terminal.
You work with Ernest in two places:

- **Hermes One (desktop app)** — your main surface. Chat, read drafts, approve or
  reject them, look at memory, turn automations on or off. Same as messaging a
  capable chief of staff who can see your mail, CRM, calendar, and Slack.
- **Slack or Telegram** — Ernest as an always-on teammate. Message it like a
  person; it replies, drafts, and asks for approval inline. This is also where
  "who-owns-what" task tracking lives.

The `ernest chat` terminal command still works and is fine for power users, but
nothing about daily work requires it.

> Hermes One is a separate desktop app (see [configure.md](configure.md#4-desktop-ui-ceo-facing)).
> The exact buttons are its UI, not Ernest's. What never changes is the rule
> below: nothing leaves your accounts until you say yes.

## The only loop you need to learn

Everything Ernest does follows one shape:

```
you ask  →  Ernest drafts  →  you approve  →  Ernest sends
```

You can ask in plain language. Ernest reads your real mail, CRM, sheets, and
Slack, then comes back with a **draft**, never a sent action. Sending an email,
writing to HubSpot, editing a Google Sheet, or posting in Slack are all blocked
until you approve. This is the draft-first gate and it cannot be skipped by
accident — see [architecture.md](architecture.md#the-gate).

**What approval looks like**

- **In the desktop app:** Ernest presents the action and its draft (recipient,
  subject, body, or the exact CRM/sheet change). You approve or reject. When
  there are several, they come as one batch so you can clear them in a pass.
- **In Slack/Telegram:** Ernest posts the draft in the thread and waits. Reply
  to approve, reject, or tell it what to change ("make it warmer", "drop the
  last line"). It re-drafts and waits again.

You are always approving a concrete thing you can read, not a vague intent. If
you reject or edit, Ernest learns the correction and applies it next time.

## Ambient: things that show up on their own

Three background jobs ship **paused**. Once your apps are connected and you've
approved a few actions, you (or whoever set Ernest up) can turn them on. After
that they appear without you asking:

- **Morning brief** (weekday mornings) — a short note in your memory vault: what
  moved, what's waiting on you, what looks at risk. Silent on quiet days.
- **Dropped-ball scan** (twice a weekday) — finds threads you went dark on and
  promises you made but didn't close, and surfaces them as cards: who, what's
  owed, how long it's been stalled, suggested next step. Drafts only.

These never send anything. They prepare; you still approve. (Details and how to
enable: [operations.md](operations.md#cron-automation).)

## The seven things you can ask for today

These ship ready. You don't set them up — just say it in plain language and
Ernest fills in the details, asking only what it can't infer. The names below
are **examples**; swap in your own people, companies, lists, and channels.

| Just say this | What Ernest does |
|---|---|
| "Add Dana to every partnership thread — I keep forgetting to loop her in." | Finds your partnership threads, drafts the loop-in (CC + a one-line context note in your voice) for each, batches them for approval. |
| "Find everyone in my inbox who looks like a strong sales hire and follow up." | Builds a vetted list from people you've actually exchanged mail with (no newsletters, no cold lists), drafts an on-voice follow-up per person referencing your last exchange. |
| "Northwind — find where I went dark and recover it." | Scans your mail and HubSpot for that one account: stalled threads, open deals gone quiet, promises you never closed. Returns ownership cards and drafts each recovery. |
| "Reconcile my Korea contacts with Sam's HubSpot list." | Diffs your inbox against that list/owner — who's missing, who's stale, who went cold — and drafts the HubSpot updates. CRM writes wait for approval. |
| "Keep the press list in sync with this Google Sheet: <url>." | Reads the live sheet, compares it to your mail and HubSpot, shows the diffs, and drafts both-side updates (sheet cells and/or CRM). |
| "Source ex-Acme founders now in the US for partnerships." | Researches new people matching the brief (web/LinkedIn), dedupes against who you already know, and drafts a tailored first-touch for each. |
| "Turn our #deals channel into who-owns-what." | Pulls commitments out of Slack into a tracker, assigns owners, and drafts a transparent status post. Posting waits for your approval, then can run on a schedule. |

Every one of these is draft-first. You will see exactly what gets sent or written
before it happens.

## Asking for something new

If your ask doesn't match the seven above, just say it anyway. Ernest looks for an
installed skill that fits; if one exists it uses it, if not it tells you plainly
rather than guessing. When the same kind of request keeps coming up, ask Ernest to
make it a reusable workflow ("we do this every week — make it a standing thing")
and it proposes one for you to approve. Connecting another app is the same: ask
("connect my calendar"), Ernest hands you a one-click authorize link, you click it.

See [use-cases.md](use-cases.md) for how the library grows.

## When something's wrong

- **Wrong tone or wording** — reject the draft and say what's off. The correction
  sticks; Ernest writes voice and decision notes into your memory vault.
- **Wrong facts** — Ernest works from your real accounts. If a name or deal looks
  wrong, the source (mail/HubSpot) is wrong; fix it there and re-ask.
- **It went too far** — it can't. Nothing external happens without your approval,
  so the worst case is a draft you decline.

## Quick reference

| You want to | Do this |
|---|---|
| Get daily work done | Message Ernest in the desktop app or Slack/Telegram |
| Approve / reject an action | Respond to the draft it shows you |
| See what it remembers | Open your memory vault (the `Ernest/` folder) |
| Turn ambient jobs on/off | In the desktop app, or see [operations.md](operations.md) |
| Connect another app | Ask Ernest; click the authorize link it returns |
| Add a new kind of task | Ask in plain language; promote repeats to a workflow |

Stuck? [troubleshooting.md](troubleshooting.md). New to Ernest? Start with
[onboarding.md](onboarding.md).
