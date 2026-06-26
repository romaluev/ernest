# Install

## The one command

**macOS · Linux · WSL · Termux**

```bash
curl -fsSL https://raw.githubusercontent.com/romaluev/ernest/main/setup.sh | bash
```

**Windows (PowerShell)**

```powershell
irm https://raw.githubusercontent.com/romaluev/ernest/main/setup.ps1 | iex
```

It does five things:

1. Installs **Hermes** if it isn't already present (only `git` is required up front; Hermes pulls its own Python/Node).
2. Installs the **Ernest** profile from this repo and creates the `ernest` command.
3. Creates a memory vault (`~/ErnestVault` by default), no prompts.
4. **Connects a model** by browser login — pick **OpenAI Codex**, **Anthropic**, or **Nous Portal**. No API keys to paste.
5. Opens **onboarding chat**, which connects apps as the first task needs them and reaches a real result in about a minute.

Two steps require you: logging into a model (Ernest needs one to run) and clicking *authorize* when Ernest hands you an app connect link. Nobody can OAuth into your HubSpot/Outlook for you.

### Zero-touch / fleet provisioning

The installer never blocks on a prompt. To pre-seed it for unattended/MDM rollout:

```bash
ERNEST_COMPOSIO_API_KEY=ck_xxx ERNEST_VAULT="$HOME/Vault" \
  bash -c "$(curl -fsSL https://raw.githubusercontent.com/romaluev/ernest/main/setup.sh)"
```

In a headless environment (no terminal), it installs cleanly and prints the two
commands to finish (`ernest model`, `ernest chat -s ernest-bootstrap`).

## What you'll want ready

- A **model**: for Ernest on VPS, set `ANTHROPIC_API_KEY` (direct Claude API). Local dev can use OAuth or an Anthropic key via `ernest model`.
- A **Composio account** (free tier) for app connections — [dashboard.composio.dev](https://dashboard.composio.dev). Optional at install time; onboarding collects it.
- **Obsidian** (optional) — the installer creates a `~/ErnestVault` folder if you don't point it at an existing vault.

## Re-running

`setup.sh` is safe to run again — it reuses your existing Hermes, refreshes the Ernest profile (`--force`, your `.env`/memories/sessions are preserved), and reopens onboarding.

## Advanced: manual install

If you already run Hermes and want to wire Ernest in by hand:

```bash
hermes profile install github.com/romaluev/ernest --name ernest --alias
ernest model            # connect a model (OAuth or key)
ernest chat -s ernest-bootstrap
```

Set `COMPOSIO_API_KEY` and `OBSIDIAN_VAULT_PATH` in `~/.hermes/profiles/ernest/.env` (the installer writes a `.env.EXAMPLE` you can copy), or let onboarding collect them.

## Production VPS (CEO does not install locally)

For a real, always-on CEO instance with live Outlook/HubSpot data:

1. Operator provisions Ubuntu VPS + Telegram bot + secrets file
2. One bootstrap command installs Ernest, Telegram gateway (systemd), watch crons, backups, firewall
3. CEO DMs @YourErnestBot in Telegram — onboarding + Composio OAuth on their accounts

From your Mac (creates Hetzner VPS + installs everything):

```bash
cp scripts/ernest.secrets.env.example ~/ernest.secrets.env   # fill in
bash scripts/deploy-ernest.sh --secrets ~/ernest.secrets.env
```

## Verify

```bash
bash scripts/verify-ernest.sh        # structural check, no network
hermes -p ernest skills list         # ernest-bootstrap, library-index, use-case-author
hermes -p ernest cron list           # 3 jobs, disabled until enabled
```

Next: [configure.md](configure.md) for details, or start onboarding — it covers the rest.
