# Install

## The one command

```bash
curl -fsSL https://raw.githubusercontent.com/romaluev/ernest/main/setup.sh | bash
```

This is everything. It:

1. Installs **Hermes** if it isn't already there (only `git` is required up front; Hermes pulls its own Python/Node).
2. Installs the **Ernest** profile from this repo and creates the `ernest` command.
3. Asks (optionally) for a **Composio key** and an **Obsidian vault folder** — press Enter to skip and do it later in chat.
4. **Connects a model** by browser login — pick **OpenAI Codex**, **Anthropic**, or **Nous Portal**. No API keys to paste.
5. Drops you into **onboarding chat**, which handles app authorization, memory, voice, and the skill library.

The only steps you cannot skip: logging into a model (Ernest can't think without one) and clicking *authorize* on your own apps when Ernest hands you a connect link. Nobody can OAuth into your HubSpot/Outlook for you.

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
