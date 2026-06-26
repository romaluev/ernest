---
name: ernest-railway
description: Headless Railway deploy from Ernest on Hostinger VPS — CLI + tokens, no browser.
version: 1.1.0
author: Notiky
license: MIT
required_environment_variables:
  - RAILWAY_API_TOKEN
  - RAILWAY_TOKEN
metadata:
  hermes:
    tags: [ernest, railway, deploy, infra, headless, hostinger]
---

# Ernest — Railway (deploy target, not where Ernest runs)

**Ernest runs on the Hostinger VPS.** Railway is where the **CEO's app** goes when they ask you to host something you built — a landing page, tool, or microsite. You are the operator; Railway is the production host.

Load this skill when the CEO says: *host this*, *deploy to Railway*, *ship the site*, *put it live*, etc.

## Architecture

```
CEO (Telegram) → Ernest on VPS (build: bash/npm/git) → Railway CLI → CEO's live URL
                      ↑ Ernest stays here              ↑ app lives here
```

## What's on the VPS (your workbench)

- Railway CLI v5 (`railway --version`)
- Node/npm (for builds)
- Shell/bash via Hermes — run `railway` commands directly; tokens come from `~/.hermes/profiles/ernest/.env`

Verify: `bash /opt/ernest/scripts/railway-verify.sh`

## Token types (Railway CLI v5)

| Token | Where | Env var | Use for |
| --- | --- | --- | --- |
| Account | [railway.app/account/tokens](https://railway.app/account/tokens) | `RAILWAY_API_TOKEN` | `railway whoami`, create/link projects |
| Project | Project → Settings → Tokens | `RAILWAY_TOKEN` | `railway up`, logs, redeploy |

**Only one env var at a time** in a single command. Do not set both.

Never write truncated keys (`8a66...f097`) into `~/.railway/config.json` or any file.

## Headless deploy (works on Hostinger — no browser)

```bash
export PATH="$HOME/.local/bin:$PATH"
set -a && source ~/.hermes/profiles/ernest/.env && set +a

cd /path/to/app
RAILWAY_TOKEN="$RAILWAY_TOKEN" railway up \
  --project "<project-id>" \
  --environment production \
  --detach
```

Or use the helper:

```bash
RAILWAY_TOKEN=... /opt/ernest/scripts/railway-deploy-headless.sh \
  --project <id> --dir /path/to/app --environment production
```

`--environment` is required with `--project`. Add `--service <name>` if multiple services.

## If CEO pastes a token in Telegram or Slack

Save it — no Hostinger, no SSH, no `ernest.secrets.env` instructions to the CEO.

```bash
bash /opt/ernest/scripts/ernest-set-secret.sh RAILWAY_API_TOKEN 'paste-full-value-here'
# or
bash /opt/ernest/scripts/ernest-set-secret.sh RAILWAY_TOKEN 'paste-full-value-here'
```

Reply: *"Got it — saved. I'll use it for deploys."* Never repeat the key in chat.

Allowed via chat: `RAILWAY_API_TOKEN`, `RAILWAY_TOKEN`, `COMPOSIO_API_KEY`, `ANTHROPIC_API_KEY`.

For a one-off deploy without saving, inline is OK: `RAILWAY_TOKEN='...' railway up ...` (still never log the token).

## When token missing

Fallback only — use **`ernest-ceo-setup`** Railway templates. CEO-friendly, one ask.

## Verify

```bash
bash /opt/ernest/scripts/railway-verify.sh
RAILWAY_TOKEN=... railway up --project <id> --environment production --detach
railway logs --project <id> --environment production
```
