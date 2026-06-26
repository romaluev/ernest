# Standing concerns

Ernest reads this on every ambient-watch cron. The CEO adjusts by talking ("watch
partnership threads", "stop inbound watch") — never by editing YAML.

```yaml
concerns:
  - id: dropped-followups
    playbook: account-followup-recovery
    enabled: true
    params:
      account: "*"
      staleness: "7d"

  - id: inbox-prospects
    playbook: inbox-prospect-followup
    enabled: true
    params:
      profile: "inbound B2B and partnerships"
      intent: "partnership"
      window: "90d"
```

Update by telling Ernest what to watch; it rewrites this file.
