# Onboarding

Onboarding is a conversation, not a setup wizard. The installer already connected
a model, so the first session starts working immediately. The goal is one real,
approved action in about a minute — then everything else fills in as you go.

## The one terminal moment

After install, start onboarding once:

```bash
ernest chat -s ernest-bootstrap
```

That's the only time you need the terminal. From the first reply on, you can move
to the desktop app or Slack/Telegram and stay there — see [daily-use.md](daily-use.md).

## What the first minute looks like

Ernest opens with one question, not a form:

> "I'm Ernest. What's the one thing you'd most like off your plate right now?"

Then it drives the shortest path to a result:

1. **Connect only what this task needs.** Ernest maps your ask to the right
   workflow and connects just the one or two apps it requires (usually mail). It
   hands you a one-click authorize link; you click it. Nobody can OAuth into your
   accounts for you, so this step is yours. It does **not** connect everything up
   front — HubSpot, Slack, Calendar wait until a task actually needs them.
2. **Do the task on real data.** Ernest runs the workflow against your real
   threads, drafts in your voice, and shows you the result for approval. The "aha"
   is the moment one real, on-voice action passes the draft-first gate because you
   approved it.
3. **Remember just enough.** Ernest confirms your memory vault (defaults to
   `~/ErnestVault`) and writes a short profile note — company, voice, your red
   lines — from what it learned doing the task. No long interview.

## What fills in afterward (never blocking)

- **More apps** connect the next time a task needs one — just ask.
- **Your preferences** (who matters most, what needs approval, the one metric
  Ernest optimizes for) get captured as real decisions come up, not in a
  questionnaire.
- **The seven workflows ship ready**, so most asks work on day one. Extra skills
  install only when a need appears.
- **Ambient automation turns on last.** The background jobs (morning brief,
  dropped-ball scan) ship paused. Once a real action has shipped and the apps a
  job needs are connected, Ernest offers to enable them. They only run while the
  gateway is up. See [operations.md](operations.md#cron-automation).

## Where Ernest is connected

Apps connect through Composio — one account at
[dashboard.composio.dev](https://dashboard.composio.dev) covers HubSpot, Outlook,
Calendar, Slack, Gmail, and 500+ others. If a Composio key was set at install,
Ernest just hands you authorize links. If not, it walks you through getting one in
chat. Either way you never edit files. Details: [configure.md](configure.md#2-composio-real-app-connectors).

## What gets written

| Location | Content |
|---|---|
| Obsidian `Ernest/00-CEO-Profile.md` | Company, voice fingerprint, red lines |
| `Ernest/.onboarded` (marker) | Set after the first approved action so later sessions skip straight to work |
| Hermes profile memory | Working summary, deepened over time by the curator |

Ernest captures your voice from your own real sent mail — it never invents
example emails.

## Re-running

Re-run `ernest chat -s ernest-bootstrap` any time to update your profile (new
focus, changed approval rules). It updates the notes rather than duplicating them.

Next: [daily-use.md](daily-use.md) for how every day actually works, or
[use-cases.md](use-cases.md) to grow what Ernest can do.
