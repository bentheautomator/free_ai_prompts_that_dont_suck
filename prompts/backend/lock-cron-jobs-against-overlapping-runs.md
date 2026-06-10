---
title: Lock Cron Jobs Against Overlapping Runs
slug: lock-cron-jobs-against-overlapping-runs
category: backend
tags: [universal, backend, jobs]
works_with: all
severity: high
one_liner: "Prevents a slow scheduled run from colliding with the next one"
---

# Lock Cron Jobs Against Overlapping Runs

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents a scheduled job that runs long from overlapping its own next invocation and double-processing everything.

**[Copy-paste ready version](../../install/lock-cron-jobs-against-overlapping-runs.md)** — just the instruction block, no explanation.

## The Problem

An AI assistant asked to "run this every 5 minutes" writes a cron entry, a `setInterval`, or a `@Scheduled(fixedRate)` annotation, and walks away. The hidden assumption: each run finishes before the next one starts. In dev, with ten test rows, a run takes 200ms and the assumption holds. In production, the dataset grows, a dependency gets slow, and one Tuesday the run takes six minutes. Now two copies of the job are processing the same rows simultaneously.

What happens next depends on the job. Email digests get sent twice. The same payments get retried by both runs. Two runs both read "unprocessed" rows, both process them, both mark them done — or they deadlock fighting over the same locks, which slows everything further, which makes the *next* run overlap too. Overlap compounds: once a job falls behind its own schedule, every subsequent tick adds another concurrent copy. Teams have found fourteen instances of the same "every 5 minutes" job grinding away at once.

Schedulers don't protect you by default. Plain cron has no overlap protection. Spring's `fixedRate` doesn't wait for completion. Kubernetes CronJob defaults to `concurrencyPolicy: Allow`. The assistant uses the default because the default works in the demo.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Lock Cron Jobs Against Overlapping Runs

NEVER schedule a recurring job without deciding what happens when a run is still going at the next tick. By default, most schedulers will happily start a second concurrent copy, and two copies of the same job double-process whatever the job touches.

- Guard every scheduled job with a mutual-exclusion mechanism that works across instances: a database advisory lock, a Redis lock with expiry (e.g., Redlock/SETNX with TTL), or the scheduler's own policy (Kubernetes `concurrencyPolicy: Forbid`, Quartz `@DisallowConcurrentExecution`, `flock` for plain cron).
- A boolean in process memory is not a lock — the next run may start on a different replica, and a crashed run leaves the boolean stuck.
- Give every lock a TTL or heartbeat so a crashed holder doesn't block the job forever. A lock that can't expire converts "double run" into "no runs ever again."
- Decide skip vs. queue explicitly: usually the right behavior is to skip the tick and log it (the work will be picked up next run). Queuing missed ticks recreates the pileup.
- Emit a metric or log when a run is skipped due to the lock, and alert if runs are skipped repeatedly — that means the job can no longer finish within its interval and needs attention.
- If the job processes rows, also make the selection atomic (`SELECT ... FOR UPDATE SKIP LOCKED` or claim-by-update) as defense in depth.

**Red flags that you're about to violate this:**
- "The job only takes a few seconds, it'll never overlap."
- "Cron handles that." (It doesn't.)
- "I'll set a flag at the start and clear it at the end."
- "There's only one instance of this service." (Until the next scale-out or blue-green deploy.)
- "Overlap is harmless here, the operations are probably idempotent."
- "I'll just make the interval longer."

---

## Why It Works

1. **It attacks the duration assumption directly.** The bug requires believing run time is constant; naming dataset growth and dependency slowness as the variables breaks that belief.
2. **It demands cross-instance exclusion.** The assistant's instinctive fix — an in-memory flag — fails on multiple replicas and on crash. Specifying advisory locks and TTLs blocks the broken fix, not just the missing one.
3. **It handles the lock's own failure mode.** A lock without TTL trades a double-run bug for a job-never-runs-again bug. The rule covers both, so the fix doesn't create a worse incident.
4. **It makes overlap observable.** Skipped-run metrics surface "the job outgrew its interval" weeks before it becomes an outage.

## Origin

A subscriptions service ran a renewal-charging job every ten minutes. A payment provider slowdown stretched one run to twenty-five minutes; the next two ticks started anyway, and three concurrent runs each pulled the same batch of "due" subscriptions. Several thousand customers were charged two or three times before the on-call killed the scheduler by hand. The postmortem fix was a `pg_advisory_lock` call — one line, plus a refund script that took considerably longer.
