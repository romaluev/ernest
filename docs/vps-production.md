# Production VPS — CEO's Ernest instance

Ernest runs 24/7 on a dedicated VPS (e.g. Hostinger). The CEO uses **Telegram** — no local install, no SSH, no CLI. Real mail/CRM/Calendar via Composio on the CEO's accounts. Slack can be connected later via Composio (optional).

**Two layers — don't mix them up:**

| Layer | What | Where |
|---|---|---|
| **Ernest runtime** | Hermes gateway, Telegram, bash, git, npm, Railway CLI, vault | VPS (always on) |
| **CEO apps Ernest ships** | Sites, tools, microsites the CEO asked for | Railway, etc. |

Ernest **builds on the VPS** and **deploys outward** when the CEO asks to host something. Ernest/Hermes is not deployed to Railway.

## VPS spec

| | Minimum | Recommended |
|---|---|---|
| OS | Ubuntu 22.04 or 24.04 LTS | Ubuntu 24.04 LTS |
| RAM | 2 GB | 4 GB |
| Disk | 20 GB | 40 GB |
| Region | Near CEO (latency) | Same timezone as CEO |
| Providers | Hetzner, DigitalOcean, Linode, Hostinger, AWS Lightsail | 4 GB RAM tier |

Telegram gateway uses **outbound polling** (or optional webhook). No public HTTP ports except SSH for you (the operator).

## Before you start (operator checklist)

### 1. Telegram bot (CEO chat)

Create via [@BotFather](https://t.me/BotFather) on Telegram:

1. Send `/newbot` and follow prompts → copy **bot token** (`123456789:ABC...`)
2. Optional: `/setdescription` — *"Your CEO operating assistant"*
3. Get CEO's **numeric user ID** — message [@userinfobot](https://t.me/userinfobot) from the CEO's account → copy the ID (e.g. `123456789`)

Set in secrets:

```bash
TELEGRAM_BOT_TOKEN=123456789:ABCdefGHIjklMNOpqrSTUvwxYZ
TELEGRAM_ALLOWED_USERS=123456789    # CEO only; comma-separated for multiple
# optional: chat ID for briefs/cron delivery (defaults to CEO DM)
# TELEGRAM_HOME_CHANNEL=123456789
```

### 2. Composio (real apps)

- Account at [dashboard.composio.dev](https://dashboard.composio.dev)
- Copy **API key**
- Pre-connect (optional): HubSpot, Outlook, Outlook Calendar, Google Sheets — or let Ernest send Connect Links during onboarding
- **Slack (optional):** CEO can connect Slack via Composio during onboarding or later — no Slack gateway required

### 3. Model API key

VPS has no browser for OAuth. Use:

- `ANTHROPIC_API_KEY` (required — direct Claude API)

Bill to your org; CEO never sees the key.

### 4. Secrets file on VPS

```bash
sudo nano /root/ernest.secrets.env
```

```bash
ANTHROPIC_API_KEY=sk-ant-...
COMPOSIO_API_KEY=ck_...
TELEGRAM_BOT_TOKEN=123456789:ABC...
TELEGRAM_ALLOWED_USERS=123456789
# optional Slack gateway (CEO can use Composio Slack instead):
# SLACK_BOT_TOKEN=xoxb-...
# SLACK_APP_TOKEN=xapp-...
# SLACK_ALLOWED_USERS=U_CEO_SLACK_ID
```

```bash
sudo chmod 600 /root/ernest.secrets.env
```

## Install (one command)

SSH to fresh VPS as root:

```bash
curl -fsSL https://raw.githubusercontent.com/romaluev/ernest/main/scripts/vps-production-bootstrap.sh | bash -s -- \
  --secrets /root/ernest.secrets.env \
  --user ernest
```

Or from your Mac (any VPS with IP + password):

```bash
cp scripts/ernest.secrets.env.example ~/ernest.secrets.env   # fill in
bash scripts/deploy-ernest.sh --secrets ~/ernest.secrets.env
```

This installs:

- Hermes + Ernest profile
- Dedicated Linux user `ernest` (CEO never uses this account)
- Telegram gateway as **systemd service** (starts on boot)
- Watch crons enabled (`daily-brief`, `ambient-watch`, `hubspot-hygiene`)
- UFW firewall (SSH in only)
- Daily backup cron (profile export + vault tarball)

Verify:

```bash
su - ernest -c 'hermes -p ernest gateway status'
su - ernest -c 'hermes -p ernest cron list'
su - ernest -c 'hermes -p ernest mcp test composio'
```

## CEO handoff (5 minutes in Telegram)

Send the CEO:

1. Open Telegram → find **@YourErnestBot** → **Start** / DM
2. Say: *"Hi Ernest"*
3. Ernest opens onboarding: *"What's the one thing you'd most like off your plate?"*
4. Ernest explains what it can automate (B2B loop-ins, follow-ups, HubSpot, sheets, sourcing)
5. CEO answers with a real task → Ernest sends **Composio Connect Links** — click **Authorize** on Outlook, HubSpot, etc.
6. Ernest offers Slack via Composio **now or later** (optional)
7. Ernest asks: *"What should I keep an eye on?"* → standing watches saved
8. First real **draft** → CEO approves in Telegram → done

After onboarding the CEO only:

- Reads **reminder cards** and morning briefs in Telegram
- Says **`draft these`** or asks in plain language when they want drafts
- Approves before anything sends

See [daily-use.md](daily-use.md).

## What runs automatically (watch-first)

| Cron | When | What CEO sees |
|---|---|---|
| `ernest-daily-brief` | weekdays 08:00 | Morning brief in Telegram/vault |
| `ernest-ambient-watch` | weekdays 11:00, 16:00 | Reminder cards (missing loop-ins, dropped follow-ups, list drift) |
| `ernest-hubspot-hygiene` | Monday 06:00 | CRM cleanup preview (mechanical auto-apply only after you opt in) |

Nothing drafts or sends without CEO approval — except mechanical HubSpot field cleanup after `hygiene_policy.approved: true` in `ernest.yaml`.

## Security model

| Layer | What |
|---|---|
| Network | UFW: only SSH inbound; Telegram via outbound polling |
| Access | `TELEGRAM_ALLOWED_USERS` = CEO only (no one else can talk to Ernest) |
| Secrets | `ernest.secrets.env` + profile `.env` mode 600; never in git |
| Actions | Draft-first gate; CEO approves every send/CRM write/sheet post |
| Data | Mail/CRM read live via Composio; vault on VPS disk; HubSpot = CRM truth |

CEO never SSHs. Their credentials are OAuth to their own Microsoft/HubSpot — not stored as passwords on the VPS.

## Railway CLI (Hostinger VPS)

Ernest can run **Railway CLI on the VPS** — the CEO does not need a local terminal or Hostinger access.

### Option A — CEO pastes keys in Telegram (recommended)

CEO sends the token in chat. Ernest runs `ernest-set-secret.sh` and confirms without echoing the key back.

Allowed via chat: `RAILWAY_API_TOKEN`, `RAILWAY_TOKEN`, `COMPOSIO_API_KEY`, `ANTHROPIC_API_KEY`.

### Option B — Operator adds to secrets file

1. CEO creates tokens at [railway.app/account/tokens](https://railway.app/account/tokens) (account) and/or per-project (Project → Settings → Tokens).
2. Operator adds to `~/ernest.secrets.env` on the VPS:

```bash
RAILWAY_API_TOKEN=...   # account — whoami, create/link projects
RAILWAY_TOKEN=...       # optional default project token for railway up
```

3. Sync and verify:

```bash
su - ernest -c 'bash /opt/ernest/scripts/finish-vps-setup.sh'
su - ernest -c 'bash /opt/ernest/scripts/railway-verify.sh'
```

4. CEO asks in Telegram: *"Deploy novalabs to Railway"* — Ernest runs `railway up` via Hermes bash on the Hostinger box.

**Headless deploy:** `RAILWAY_TOKEN` + `railway up --project <id> --environment production --detach`. No `railway login` browser flow required.

## Operations (you, not the CEO)

```bash
# Logs
su - ernest -c 'tail -f ~/.hermes/profiles/ernest/logs/agent.log'

# Restart gateway
su - ernest -c 'hermes -p ernest gateway restart'

# Update Ernest (preserves .env, vault, memories)
su - ernest -c 'hermes profile update ernest'

# Manual backup
su - ernest -c 'bash ~/.hermes/profiles/ernest/scripts/backup-ernest.sh'

# Health
su - ernest -c 'bash ~/.hermes/profiles/ernest/scripts/verify-ernest.sh'
su - ernest -c 'hermes -p ernest mcp test composio'
```

Backups land in `~/ernest-backups/` (14-day retention).

## Troubleshooting

| Symptom | Fix |
|---|---|
| Bot silent in Telegram | `gateway status`; check `TELEGRAM_BOT_TOKEN` in `.env`; verify `TELEGRAM_ALLOWED_USERS` includes CEO's numeric ID |
| Composio tools fail | `mcp test composio`; verify key; CEO re-authorizes app in dashboard |
| Crons never fire | Gateway must be running; `cron list` shows enabled |
| CEO can't authorize app | Send Connect Link again; check Composio dashboard for that toolkit |
| Want Slack too | Connect Slack via Composio (onboarding) or add Slack gateway tokens to secrets and restart |

See [troubleshooting.md](troubleshooting.md).

## Private repo

If `romaluev/ernest` is private, copy scripts to VPS:

```bash
scp scripts/vps-production-bootstrap.sh scripts/backup-ernest.sh root@VPS:/root/
ssh root@VPS 'bash /root/vps-production-bootstrap.sh --secrets /root/ernest.secrets.env'
```

Or add a deploy key / `GITHUB_TOKEN` for `git clone`.
