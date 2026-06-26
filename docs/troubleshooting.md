# Troubleshooting

## Install

**`hermes: command not found`** — Install Hermes first: <https://github.com/NousResearch/hermes-agent>. Confirm with `hermes --version` (need ≥ 0.12.0).

**Distribution won't install** — Run from the repo root (must contain `distribution.yaml`), or use a git URL. Check `hermes profile info ernest`.

## Model

**"No provider configured" on first chat** — Add `ANTHROPIC_API_KEY` to `~/.hermes/profiles/ernest/.env` and confirm `config.yaml` has `provider: anthropic`.

## Composio

**`mcp test composio` fails / times out** — Check `COMPOSIO_API_KEY` is set in the profile `.env`, `npx` is installed, and you've authorized at least one toolkit at [dashboard.composio.dev](https://dashboard.composio.dev).

**Tool exists but returns auth error** — The toolkit isn't connected for your account. Authorize it in the Composio dashboard, then `hermes -p ernest mcp test composio`.

## Obsidian

**`mcp test obsidian` fails** — `OBSIDIAN_VAULT_PATH` must be an absolute path to an existing folder. Avoid simultaneous writes from Obsidian desktop and Ernest to the same note (sync lock).

## Skills

**A skill won't install** — `hermes -p ernest skills inspect <identifier>` to preview; check trust/source. Community skills are reviewed case-by-case by policy.

**Skill not triggering** — Its `description` drives auto-selection. Invoke explicitly: `ernest chat -s <skill-name>`.

## Cron

**Jobs never run** — They're disabled on install and need the scheduler. `hermes -p ernest cron enable <id>` then `hermes -p ernest gateway run`/`start`.

**Sub-agent "iteration exhaustion"** — `config.yaml` sets `delegation.max_iterations: 100` and `child_timeout_seconds: 1200`; restart the session after changes.

## Gate

**Ernest refuses to send** — By design. External send/publish/write is draft-only until the CEO approves. To approve, confirm in chat/desktop. Adjust levels in `ernest.yaml → approval_defaults` (do not lower L3).

## Reset

```bash
hermes profile update ernest --force-config   # reset config to distribution default
hermes profile delete ernest --yes            # full removal (keeps nothing)
```
