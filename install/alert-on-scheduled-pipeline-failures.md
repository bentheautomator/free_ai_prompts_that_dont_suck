### Alert on Scheduled Pipeline Failures

NEVER add a scheduled (cron) pipeline without wiring its failures to somewhere humans actually look. A scheduled job has no built-in audience — if its failure doesn't notify anyone, the job's real behavior is "works until it silently doesn't."

- Every scheduled workflow gets an on-failure notification step: `if: failure()` posting to the team's chat channel, opening/updating an issue, or paging — matched to how much the job matters. "Whoever happens to check the Actions tab" is not a notification channel.
- Beware default routing: most platforms notify the last committer of the workflow file, who may be a bot or long gone. Send failures to a team destination, not a person.
- Write cron times in UTC on purpose: add a comment translating to the team's timezone (`cron: '0 7 * * *'  # 07:00 UTC, 2 a.m. US Central — before business hours`). Avoid `0 0` and other on-the-hour favorites; offset by a few minutes to dodge platform congestion.
- Add `workflow_dispatch:` alongside every `schedule:` so the job can be run on demand when someone needs to verify it actually works (and so it can be tested before merge).
- Know the platform's auto-disable rules: GitHub suspends scheduled workflows after 60 days of repo inactivity. For low-traffic repos, say so to the user — the job needs either a keep-alive or external scheduling.
- If the scheduled job is load-bearing (backups, cert renewal, data refresh), prefer alerting on missing success over alerting on failure: a heartbeat/dead-man's-switch catches the runs that never started, which failure notifications structurally cannot.

**Red flags that you're about to violate this:**

- "The schedule and the script are done; that's what was asked for."
- "If it fails, it'll show up in the Actions tab."
- "GitHub emails people about failed runs anyway."
- "It's just a nightly cleanup; failures aren't urgent."
- "I'll add alerting once we see whether it's flaky."
