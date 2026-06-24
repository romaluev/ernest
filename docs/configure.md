# Configure

All configuration is native Hermes. Ernest adds no custom config system.

## 1. Model

```bash
ernest setup            # interactive: provider, model, gateway
# or section-only:
ernest setup model
```

`config.yaml` defaults to `anthropic/claude-sonnet-4` with `provider: auto`. Override in setup or by editing `~/.hermes/profiles/ernest/config.yaml`.

## 2. Composio (real app connectors)

The Composio MCP is pre-wired in `config.yaml` as a remote HTTP server (Composio's official Hermes integration):

```yaml
mcp_servers:
  composio:
    url: "https://connect.composio.dev/mcp"
    headers:
      x-consumer-api-key: "${COMPOSIO_API_KEY}"
```

Steps:

1. Get your Connect MCP URL + API key at [dashboard.composio.dev](https://dashboard.composio.dev); set `COMPOSIO_API_KEY` in the profile `.env`.
2. Authorize the toolkits the CEO needs: **HubSpot, Outlook, Outlook Calendar, Slack** (Gmail optional). Either pre-connect in the dashboard, or let Ernest hand you a Connect Link on first use.
3. Restart the agent, then confirm tools resolve: `hermes -p ernest mcp test composio`.

One key covers 500+ apps. Add or remove toolkits in the Composio dashboard — no config change needed.

## 3. Obsidian (memory)

```yaml
mcp_servers:
  obsidian:
    command: npx
    args: ["-y", "obsidian-mcp", "${OBSIDIAN_VAULT_PATH}"]
```

Set `OBSIDIAN_VAULT_PATH` to an absolute vault path. Ernest reads/writes notes under `Ernest/` (profile, north-star, daily briefs). Keep Obsidian's own sync (iCloud/Syncthing) for multi-device.

## 4. Desktop UI (CEO-facing)

Install [Hermes One](https://github.com/fathah/hermes-desktop), choose **local backend**, and select the `ernest` profile. It gives the CEO a GUI for chat, skills, cron, memory, and gateways over the same profile.

## 5. Gateway (optional — Slack/Telegram/etc.)

```bash
ernest setup gateway
```

To run Ernest as an always-on Slack teammate, configure the Slack gateway and start the service (see [operations.md](operations.md)). Until then, use desktop or `ernest chat`.

## Approval gate

`plugins.enabled: [ernest-enforcement]` blocks external send/publish/write until the CEO approves. Approval levels live in `ernest.yaml` (`approval_defaults`). See [architecture.md](architecture.md#the-gate).

Next: [onboarding.md](onboarding.md).
