# Onboarding

Onboarding is a **skill** (`ernest-bootstrap`), not a script. The CEO runs one command and Ernest drives the rest, confirming at each external step.

```bash
ernest chat -s ernest-bootstrap
```

## The flow

1. **Connect apps.** Ernest checks `COMPOSIO_API_KEY` and asks the CEO to authorize HubSpot, Outlook, Calendar, and Slack at [app.composio.dev](https://app.composio.dev). It verifies each returns live tools.
2. **Set memory.** Confirms `OBSIDIAN_VAULT_PATH`, creates `Ernest/00-CEO-Profile.md` and `Ernest/North-Star.md` in the vault.
3. **Interview.** Only what changes behavior: company + ICP + red lines, relationship tiers, approval preferences, the North-Star metric (friction + outcome).
4. **Capture voice.** Reads 15–20 of the CEO's real Outlook sent emails to ground voice; stores a short fingerprint note. No invented samples.
5. **Install the library.** Runs `scripts/install-skills.sh` (see [use-cases.md](use-cases.md)).
6. **Prove it.** Runs one real dropped-ball scan on the live inbox, drafts one real reply in the CEO's voice, and the CEO approves it in the gate.

**Done when** one real, on-voice, approved action has shipped.

## What gets written

| Location | Content |
|---|---|
| `~/.hermes/profiles/ernest/memories/USER.md` | CEO profile summary |
| Obsidian `Ernest/00-CEO-Profile.md` | Company, ICP, tiers, rules |
| Obsidian `Ernest/North-Star.md` | The metric Ernest optimizes |
| `memory/*.md` (templates) | Filled from the answers above |

## Re-running

Onboarding is idempotent — re-run `ernest chat -s ernest-bootstrap` any time to update the profile (e.g. new vertical, changed approval rules). It updates the notes rather than duplicating them.

Next: [use-cases.md](use-cases.md) to add capabilities, or [operations.md](operations.md) to turn on automation.
