# Daily use

Install is one terminal step (or your operator provisions a **production VPS** — see [vps-production.md](vps-production.md)). Daily work: **Telegram** (VPS or local gateway), **Hermes One desktop**, or optionally Slack.
CLI (`ernest chat`) is install/onboarding and power users only.

**CEO on VPS:** open Telegram → DM @YourErnestBot. Reminder cards, briefs, drafts, and approvals all happen there. No SSH, no CLI.

> Hermes One is a third-party desktop app. Nothing leaves your accounts until you approve — except mechanical HubSpot hygiene after you opt in (see [operations.md](operations.md#hubspot-hygiene)).

## Two modes

| Mode | Who starts it | What happens |
|---|---|---|
| **Watch** | Cron (`ernest-ambient-watch`, `ernest-daily-brief`) | Detect slips/drift → reminder cards. **No drafts.** |
| **Draft** | You ask, or tap/reply **`draft these`** on a card | Ernest prepares email/CRM/sheet content → you approve → it sends |

Default is watch. Drafting requires your explicit ask (including one-tap on a card).

## What Ernest watches (automatic)

Configured once in onboarding ("what should I keep an eye on?") → `memory/standing-concerns.md`. Examples:

| You told Ernest to watch | It reminds you when |
|---|---|
| Teammate missing on partnership threads | B2B threads without that CC |
| Dropped follow-ups on important contacts | You went dark 7+ days |
| Korea list vs your mail | Inbox and Alvin's HubSpot list diverge |
| Press list vs Google Sheet | Row/status drift |

Schedule: `ernest-ambient-watch` weekdays 11:00 & 16:00; `ernest-daily-brief` weekday 08:00. Both paused until enabled; need gateway running ([operations.md](operations.md)).

Reminder cards land in `Ernest/00-Watch/` (and Telegram if configured). Each card includes **Draft these** — that tap is your ask to prepare actions.

## HubSpot hygiene (Monday cron)

Replaces manual cleanup (junk symbols, trim, dedupe, later: translations, status, priority). Default: **preview only** (`dry_run: true`). After you approve the hygiene policy, mechanical fixes auto-apply; judgment calls stay in a review batch. See [operations.md](operations.md#hubspot-hygiene).

## What you ask Ernest to draft

Direct ask or **`draft these`** on a card:

| Ask | Draft-half does |
|---|---|
| "Add Dana to every partnership thread" | Loop-in drafts per thread |
| "Follow up with sales candidates in my mail" | On-voice follow-up drafts |
| "Northwind — recover where I went dark" | Recovery message drafts |
| "Reconcile Korea with Sam's HubSpot list" | CRM update batch |
| "Sync press list with this Sheet \<url\>" | Sheet + CRM update batch |
| "Source ex-Acme founders in the US" | Research list + first-touch drafts |
| "Turn #deals into who-owns-what" | Tracker + digest drafts (connect Slack via Composio) |

Every draft waits for approval. Reject → Ernest records the correction.

## Build & host (ship something Ernest made)

Ernest runs on the **VPS** (workbench). When you ask to **host** something — a landing page, tool, or microsite — Ernest builds there and deploys to **Railway** (or similar). Ernest itself is not what gets hosted.

| Ask | What happens |
|---|---|
| "Build a contacts page for NovaLabs" | Ernest scaffolds on the VPS |
| "Host it on Railway" / "Put it live" | Ernest runs `railway up` from the VPS → returns the URL |
| "Update the live site" | Ernest edits the build, redeploys |

Operator sets Railway tokens once on the VPS — see [vps-production.md](vps-production.md#railway-cli-hostinger-vps). You approve before anything goes public if Ernest asks.

**Or paste keys in Telegram** — Ernest saves Railway / Composio / Anthropic keys from chat; no Hostinger access needed.

## Quick reference

| Goal | Action |
|---|---|
| See what's slipping | Read reminder cards / morning brief |
| Get drafts prepared | Tap **Draft these** or ask in plain language |
| Add a watch | Tell Ernest ("watch X"); it updates standing concerns |
| Turn crons on | Desktop or `hermes -p ernest cron enable …` |
| Connect an app | Ask Ernest; click authorize link |
| Add Slack later | Ask Ernest to connect Slack via Composio |

[faq.md](faq.md) · [onboarding.md](onboarding.md) · [troubleshooting.md](troubleshooting.md)
