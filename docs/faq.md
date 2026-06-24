# FAQ

Plain answers to the questions a CEO actually asks before trusting Ernest with
real accounts.

### What can Ernest do?

It works your mail, CRM, calendar, Slack, and Google Sheets the way a chief of
staff would: find dropped threads, draft follow-ups in your voice, reconcile your
inbox with HubSpot, sync a list with a sheet, source new contacts, loop teammates
into the right threads, and turn Slack into transparent task tracking. Eight
playbooks ship ready — see [daily-use.md](daily-use.md).

### What can't it do?

It doesn't send, write, or post anything on its own (see the next question). It
won't act on accounts you haven't connected, and it won't fabricate data — if an
app isn't connected, it says so instead of guessing. Money, legal commitments,
deletions, and permission changes are off-limits to automation by design and stay
manual. It is not a CRM, a model, or a custom app — it's a curation and safety
layer over the open-source Hermes agent.

### Will it ever send or write without me?

**Email, Slack, sheets:** No. Blocked until you approve.

**HubSpot:** Almost always blocked until you approve. **One exception:** after you
opt into `hygiene_policy` (`dry_run: false`, `approved: true`), the Monday hygiene
cron may auto-fix **mechanical** fields only — strip junk symbols, trim whitespace,
exact dedupe on name/company fields. Translations, status, priority, fuzzy dedupe,
and deal creation stay in review batches. Snapshots and audit log every run.

**Watch crons:** Remind only. They never draft email or CRM content. Tap **draft these**
on a card when you want drafts prepared.

### What happens when I'm away?

Watch crons keep running (if gateway is up). They write reminder cards and the
morning brief — **no drafts, no sends**. You return to a list of what slipped, not
actions you didn't authorize. `[SILENT]` on quiet days.

### What does it need from me to start?

Three things, and only the first two are unavoidable: a model login (so it can run
— handled by the installer), and a click on the authorize link for the first app a
task needs (nobody can log into your accounts for you). The third is telling it
what you want off your plate. That's onboarding — see [onboarding.md](onboarding.md).

### Where does my data live? Is it private?

Your mail, CRM, and contacts stay in your own accounts — Ernest reads them live
through Composio and doesn't copy them into a separate database. Long-term memory
(your profile, voice notes, briefs) lives in a local Obsidian vault you own and can
read or delete at any time. HubSpot remains the source of truth for
contacts and pipeline. Your model provider processes the text Ernest sends it, as
with any AI tool; choose the provider you're comfortable with at install.

### How do I correct it when it's wrong?

Reject the draft and tell it what's off ("too formal", "wrong person", "drop that
line"). Ernest re-drafts and records the correction in your memory vault, so voice
and decision preferences improve over time. If a fact looks wrong, it's coming from
your live accounts — fix it at the source (mail/HubSpot) and re-ask.

### What happens after onboarding — what's next?

After your first approved action, Ernest closes the session by telling you what
just shipped, naming two or three high-value next steps it actually saw in your
data (stalled threads, a drifting list, an intro you keep forgetting), offers to
turn on watch crons (`ernest-daily-brief`, `ernest-ambient-watch`), and explains:
Ernest **watches and reminds** by default; say **`draft these`** or ask when you
want drafts prepared.

### How do I add a new kind of task or use-case?

Ask in plain language. Ernest checks for an installed skill that fits and uses it;
if none does, it says so. When the same request recurs, ask it to make a standing
workflow and it proposes one for you to approve. Full mechanics:
[use-cases.md](use-cases.md).

### How do I connect another app?

Ask ("connect my calendar", "add Slack"). Ernest hands you a one-click authorize
link; you click it. One Composio account covers 500+ apps with no config editing.
See [configure.md](configure.md#2-composio-real-app-connectors).

### How do I update Ernest, or undo a bad change?

Updates and rollback are operator tasks, not daily ones. A profile update refreshes
Ernest while preserving your memory, sessions, and settings; the profile can be
exported as a backup. Because nothing external happens without approval, a "bad
change" is almost always just a draft you decline — there's nothing to undo. See
[operations.md](operations.md#update).

### Which interface should I use — desktop, Slack, or CLI?

- **Desktop app (Hermes One):** your daily home. Chat, approvals, memory,
  automations in one place.
- **Slack / Telegram:** when you'd rather just message a teammate, and the home for
  Slack-driven task tracking. Approvals happen inline.
- **CLI (`ernest chat`):** only for the one-time install/onboarding and for power
  users who like the terminal. You don't need it for daily work.

See [daily-use.md](daily-use.md).

### Is it safe to use on my real accounts?

Yes, and the draft-first gate is the reason: it can read and prepare freely, but it
cannot send, write, post, or delete without your explicit approval. Start with one
app and one task, approve a few drafts to see how it behaves, then connect more. Two
caveats remain true: Ernest is only as accurate as the accounts it reads, and the
desktop app (Hermes One) is a separate third-party tool whose exact UI is its own.
The safety rule holds across every surface.
