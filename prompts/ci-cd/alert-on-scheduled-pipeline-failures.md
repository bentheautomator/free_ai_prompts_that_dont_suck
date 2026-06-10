---
title: Alert on Scheduled Pipeline Failures
slug: alert-on-scheduled-pipeline-failures
category: ci-cd
tags: [universal, ci]
works_with: all
severity: medium
one_liner: "Stops the AI from adding cron pipelines that fail silently for months"
---

# Alert on Scheduled Pipeline Failures

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from creating scheduled workflows whose failures nobody is positioned to see.

**[Copy-paste ready version](../../install/alert-on-scheduled-pipeline-failures.md)** — just the instruction block, no explanation.

## The Problem

A PR pipeline that fails has a built-in audience: the person trying to merge. A scheduled pipeline that fails at 3 a.m. has an audience of zero. There's no PR to block, no red X in anyone's way, no human waiting on the result. The run fails, the next night's run fails the same way, and the nightly backup job, dependency audit, stale-data refresh, or certificate renewal quietly becomes a job that hasn't succeeded since the runner image changed in March. Scheduled workflows are precisely the ones doing work too important to do manually — and they're the only category of pipeline whose failure notifies nobody by default.

The platforms make this worse in quiet ways. Default notification settings route scheduled-run failures to whoever wrote the workflow's last commit — often a bot, or someone who left. GitHub disables cron workflows entirely after 60 days without repository activity, which means your safety net has a built-in expiry nobody scheduled. And cron syntax itself loves an ambush: times are UTC (your "nightly 2 a.m." job runs mid-afternoon in some office), and popular times like `0 0 * * *` are so oversubscribed that runs get delayed or dropped.

Assistants create silent cron jobs because the task is "add a scheduled job," and the schedule plus the script is, textually, the whole task. Failure delivery isn't part of the prompt, isn't part of the YAML examples, and isn't testable in the PR — so it doesn't exist.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

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

---

## Why It Works

1. **It supplies the missing audience.** Every other pipeline failure interrupts a human mid-task; the rule manufactures that interruption for the one pipeline class that lacks it.
2. **Heartbeats beat failure alerts for load-bearing jobs** because the worst scheduled-job failure is the run that never happened — disabled workflow, expired schedule, dropped trigger — and only absence-of-success detection can see a run that doesn't exist.
3. **It encodes the platform traps as checklist items** (UTC, congestion, last-committer routing, 60-day auto-disable), each of which is individually obscure and collectively responsible for most silent cron deaths.
4. **The dispatch trigger keeps the job verifiable on demand**, converting "I assume the nightly job still works" into a one-click fact.

## Origin

A nightly workflow refreshed the analytics warehouse from production replicas. After a repo reorganization changed a path, the job began failing every night — notifying only its last committer, a service account with no inbox. Four months later a quarterly business review was assembled from a warehouse frozen in the previous quarter, and the discrepancy was caught by a director who remembered a number being different. The fix was a two-line path update; the recomputation and the explanation took substantially longer.
