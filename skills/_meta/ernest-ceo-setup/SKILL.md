---
name: ernest-ceo-setup
description: Fallback when Ernest is blocked — missing key, app not connected, expired OAuth. Warm one-step CEO instructions via Telegram/Slack only. Not the main flow.
version: 1.1.0
author: Notiky
license: MIT
metadata:
  hermes:
    tags: [ernest, setup, fallback, ceo, keys, composio]
    related_skills: [ernest-bootstrap, ernest-railway]
---

# Ernest — CEO setup fallback

**Use only when you're blocked** — auth failed, app not connected, key missing, link expired. Normal work never mentions setup.

This is a **fallback**, not onboarding and not the default voice. Try the task first; if a tool errors or returns unauthorized, switch to this skill for **one friendly ask**, then get back to work.

## Tone

- Talk like a colleague, not IT support.
- One ask per message. No numbered post-mortems, no architecture, no Hostinger/SSH/`.env`/operators.
- OAuth → "one tap." Keys → "paste it here." Then you handle the rest.
- After they help: thank briefly, **finish what they originally asked for**.

## When to use (triggers)

| You're blocked because… | Fallback |
|---|---|
| HubSpot / Outlook / Slack not connected | Connect link |
| Composio itself down (no API key) | Paste Composio key |
| Railway deploy (no token) | Paste Railway token |
| Connect link expired | Fresh link |
| Model/provider error (and CEO might have a key) | Soft ask or operator note |
| Telegram bot broken | Operator note only — don't ask CEO to fix |

## Fallback messages (adapt, don't read like a manual)

### App not connected

Generate link via `COMPOSIO_MANAGE_CONNECTIONS`, then:

> Quick thing — I need your **{App}** hooked up before I can do this. One tap, ~30 sec, your password stays with {App}:
>
> {link}
>
> Ping me when done.

### Composio key missing (rare)

> Looks like I'm missing my Composio hookup. Grab your key from [dashboard.composio.dev](https://dashboard.composio.dev) and paste it here — I'll tuck it away and we can move on.

Then: `bash /opt/ernest/scripts/ernest-set-secret.sh COMPOSIO_API_KEY '...'`

### Railway — ship something live

Prefer project token (fastest):

> Almost there. To put this live I need a Railway token — Project → Settings → Tokens → Generate, then paste it here. I'll handle deploy and send you the URL.

Or account token:

> To deploy on Railway, paste your account token from [railway.app/account/tokens](https://railway.app/account/tokens). One time, then I'm good.

Then: `ernest-set-secret.sh RAILWAY_TOKEN '...'` or `RAILWAY_API_TOKEN`, then deploy.

### They pasted a key

1. `bash /opt/ernest/scripts/ernest-set-secret.sh {KEY} '{full value}'`
2. Reply: **"Got it — picking up where we left off."**
3. Do the original task. Never repeat the key.

Truncated paste (`8a66...f097`): **"Looks like that got cut off — mind pasting the whole thing?"**

Allowed via chat: `RAILWAY_API_TOKEN`, `RAILWAY_TOKEN`, `COMPOSIO_API_KEY`, `ANTHROPIC_API_KEY`.

### Link expired

> That link timed out — here's a fresh one: {link}

### Model/backend down (CEO can't fix)

> I'm having trouble on my end reaching the model. Give me a minute — if it persists, your operator may need to refresh the server key. I'll let you know.

Only offer Anthropic key paste if you know they manage billing.

### Operator-only (bot broken, locked out)

> Something's off on my side — shouldn't need anything from you. Try me again in a few min.

Never ask CEO for `TELEGRAM_*` or Slack gateway tokens.

## Close the loop

After unblock:

> **{App}** connected — pulling your mail now.

> Token saved — deploying now, URL in a sec.

One line. Then do the work.
