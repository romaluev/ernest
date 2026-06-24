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

This is everything. It:

1. Installs **Hermes** if it isn't already there (only `git` is required up front; Hermes pulls its own Python/Node).
2. Installs the **Ernest** profile from this repo and creates the `ernest` command.
3. Creates a memory vault (`~/ErnestVault` by default) — **no prompts**.
4. **Connects a model** by browser login — pick **OpenAI Codex**, **Anthropic**, or **Nous Portal**. No API keys to paste.
5. Drops you into **onboarding chat**, which connects apps as the first task needs them and gets you to a real result in about a minute.

The only steps you cannot skip: logging into a model (Ernest can't think without one) and clicking *authorize* on your own apps when Ernest hands you a connect link. Nobody can OAuth into your HubSpot/Outlook for you.

### Zero-touch / fleet provisioning

The installer never blocks on a prompt. To pre-seed it for unattended/MDM rollout:

```bash
ERNEST_COMPOSIO_API_KEY=ck_xxx ERNEST_VAULT="$HOME/Vault" \
  bash -c "$(curl -fsSL https://raw.githubusercontent.com/romaluev/ernest/main/setup.sh)"
```

In a headless environment (no terminal), it installs cleanly and prints the two
commands to finish (`ernest model`, `ernest chat -s ernest-bootstrap`).

## What you'll want ready

- A **model**: an OpenAI/ChatGPT, Anthropic, or Nous Portal login (OAuth — no key needed), *or* an OpenRouter/Anthropic/OpenAI API key if you prefer.
- A **Composio account** (free tier) for app connections — [dashboard.composio.dev](https://dashboard.composio.dev). Optional at install time; onboarding can walk you through it.
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

## Verify

```bash
bash scripts/verify-ernest.sh        # structural check, no network
hermes -p ernest skills list         # ernest-bootstrap, library-index, use-case-author
hermes -p ernest cron list           # 3 jobs, disabled until enabled
```

Next: [configure.md](configure.md) for the details, or just start chatting — onboarding covers it.
