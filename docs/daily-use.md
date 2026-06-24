# Daily use

Install is a one-time terminal step. After that you work with Ernest in two places:

- **Hermes One (desktop app)** — your main surface. Chat, read drafts, approve or
  reject them, view memory, turn automations on or off. It works like messaging a
  chief of staff who can see your mail, CRM, calendar, and Slack.
- **Slack or Telegram** — Ernest as an always-on teammate. Message it like a
  person; it replies, drafts, and asks for approval inline. This is also where
  who-owns-what task tracking lives.

The `ernest chat` terminal command still works for power users, but daily work
does not require it.

> Hermes One is a separate desktop app (see [configure.md](configure.md#4-desktop-ui-ceo-facing)).
> The exact buttons are its UI, not Ernest's. The rule below holds on every
> surface: nothing leaves your accounts until you approve.

## The loop

Everything Ernest does follows one shape:

```
you ask  →  Ernest drafts  →  you approve  →  Ernest sends
```

Ask in plain language. Ernest reads your real mail, CRM, sheets, and Slack, then
returns a **draft**, never a sent action. Sending an email, writing to HubSpot,
editing a Google Sheet, and posting in Slack are blocked until you approve. This is
the draft-first gate, enforced in code — see [architecture.md](architecture.md#the-gate).

**What approval looks like**

- **In the desktop app:** Ernest presents the action and its draft (recipient,
  subject, body, or the exact CRM/sheet change). You approve or reject. When
  there are several, they come as one batch so you can clear them in a pass.
- **In Slack/Telegram:** Ernest posts the draft in the thread and waits. Reply
  to approve, reject, or tell it what to change ("make it warmer", "drop the
  last line"). It re-drafts and waits again.

You always approve a concrete thing you can read, not a vague intent. If you
reject or edit, Ernest records the correction and applies it next time.

## Ambient jobs

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

These ship ready; you don't set them up. Say it in plain language and Ernest fills
in the details, asking only what it can't infer. The names below are **examples**;
swap in your own people, companies, lists, and channels.

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

If your ask doesn't match the seven above, say it anyway. Ernest looks for an
installed skill that fits; if one exists it uses it, if not it says so rather than
guessing. When the same request keeps recurring, ask Ernest to make it a reusable
workflow ("we do this every week — make it a standing thing") and it proposes one
for you to approve. Connecting another app works the same way: ask ("connect my
calendar"), Ernest hands you a one-click authorize link, you click it.

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

See [troubleshooting.md](troubleshooting.md) for issues, or
[onboarding.md](onboarding.md) for the first-run flow.
