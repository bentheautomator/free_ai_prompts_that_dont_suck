---
title: Stop Timers From Overlapping Themselves
slug: stop-timers-from-overlapping-themselves
category: concurrency
tags: [universal, concurrency, timers]
works_with: all
severity: high
one_liner: "Stops intervals that fire again while the previous run is still executing"
---

# Stop Timers From Overlapping Themselves

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from scheduling periodic work with fixed-rate timers that fire again while the previous run is still going, stacking concurrent copies of a job that assumes it runs alone.

**[Copy-paste ready version](../../install/stop-timers-from-overlapping-themselves.md)** — just the instruction block, no explanation.

## The Problem

`setInterval(syncOrders, 30_000)` reads as "sync orders every 30 seconds." What it actually says is "*start* syncing orders every 30 seconds, regardless of whether the last sync finished." The day the downstream API slows down and a sync takes 45 seconds, two syncs run concurrently. They process the same pending rows, double-send the same records, and contend for the same resources, which slows both down, which means the next tick adds a third. This is a self-amplifying failure: slowness creates overlap, overlap creates more slowness, and an interval that ran clean for a year piles up into a stampede during the exact incident when you can least afford it. Cron has the same trap: a `* * * * *` job with no overlap guard runs 2..n copies the moment runtime exceeds a minute.

AI assistants write fixed-rate timers because the requirement is phrased that way ("every 30 seconds") and because `setInterval` is the first tool the language hands you. The body's duration is invisible at the call site, and in tests the body completes in milliseconds, so the overlap never happens until production latency makes it happen. `setInterval` also doesn't await async callbacks — it cannot, structurally, wait for the work it triggers.

Periodic jobs almost always mean "with 30 seconds *between* runs," and the gap between that and "every 30 seconds" is exactly one slow run wide.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Stop Timers From Overlapping Themselves

NEVER schedule periodic work with a fixed-rate timer that can fire while the previous run is still executing. Schedule the next run only after the current run finishes.

`setInterval` and bare cron start work on a clock, not on completion; one slow run means two concurrent runs, and concurrent runs of a job built to run alone means duplicates and contention.

- Use the recursive form: run the job, and in its completion path (success *and* failure), `setTimeout(loop, delay)`. In Python: `while True: await job(); await asyncio.sleep(delay)` in a single task. This makes overlap impossible by construction.
- `setInterval(asyncFn, ms)` is always wrong for async work: the interval doesn't await the callback, so the timer and the work are unrelated schedules.
- Wrap the body in try/catch/finally; an unhandled rejection that skips the rescheduling line kills the loop forever, silently. A periodic job that can stop must also be observable (log each run, alert on absence).
- If the schedule genuinely must be fixed-rate (run at :00 exactly), add an explicit overlap policy: an in-process running flag at minimum, a distributed lock or lease if multiple instances run the schedule — skip or queue, but decide.
- Cron jobs need the same: `flock`, a lock table, or your scheduler's concurrency policy (e.g. forbid). Assume the job will someday outlive its period.
- On shutdown, cancel the timer and wait for an in-flight run before tearing down what it uses.

**Red flags that you're about to violate this:**
- "The job takes 2 seconds and runs every 5 minutes; overlap is impossible."
- "setInterval is the standard way to do something periodically."
- "If it overlaps occasionally, the runs are independent anyway." (They share the same pending rows.)
- "The interval callback is async, so it'll just await naturally."
- "I'll keep the interval and make the body faster."

---

## Why It Works

1. **Schedule-after-completion eliminates the bug structurally** — there is no flag to forget and no policy to misconfigure, because a next run cannot exist until the current one ends.
2. **It names the amplification loop** (slow → overlap → slower → more overlap), so the AI stops modeling overlap as a benign occasional duplicate and starts modeling it as a stampede.
3. **The try/finally requirement covers the dual failure mode:** loops that overlap and loops that silently die are two sides of the same missing completion-handling.
4. **It forces an explicit overlap policy where fixed-rate is real,** converting "probably won't happen" into skip/queue/lock, all of which are checkable in review.

## Origin

A reconciliation job ran on a one-minute interval and normally finished in eight seconds. A vendor API brownout pushed runtimes past four minutes; five concurrent reconcilers processed the same unsettled transactions, each marking them settled and emitting payout instructions. The payouts deduplicated downstream — mostly. The postmortem traced eleven double-payments to a single line of `setInterval`, and the fix was the oldest pattern in the book: do the work, *then* set the timer.
