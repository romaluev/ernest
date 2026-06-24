# Standing concerns

Ernest reads this file on every ambient-watch cron run. The CEO fills it by
asking ("keep Dana on all partnership threads", "watch follow-ups older than 7
days") — never by editing YAML. Each entry maps to a playbook watch-half.

```yaml
concerns:
  # - id: loop-partnerships
  #   playbook: loop-in-teammate
  #   enabled: true
  #   params:
  #     teammate: "Dana"
  #     segment: "partnership"
  #     window: "90d"
  #
  # - id: dropped-followups
  #   playbook: account-followup-recovery
  #   enabled: true
  #   params:
  #     account: "*"          # all important contacts
  #     staleness: "7d"
  #
  # - id: hubspot-alvin-list
  #   playbook: hubspot-list-reconcile
  #   enabled: true
  #   params:
  #     segment: "Korea"
  #     hubspot_target: "Alvin list"
  #
  # - id: press-sheet
  #   playbook: sheet-contact-sync
  #   enabled: false
  #   params:
  #     entity: "press"
  #     sheet_url: ""
```

Update by telling Ernest what to watch; it rewrites this file.
