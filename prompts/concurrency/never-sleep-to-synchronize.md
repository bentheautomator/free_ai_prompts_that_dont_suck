---
title: Never Sleep to Synchronize
slug: never-sleep-to-synchronize
category: concurrency
tags: [universal, concurrency, async]
works_with: all
severity: high
one_liner: "Stops sleep(2000) being used as a synchronization primitive"
---

# Never Sleep to Synchronize

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from using sleeps and arbitrary delays to "wait" for another operation to finish, encoding a guess about timing as if it were a guarantee.

**[Copy-paste ready version](../../install/never-sleep-to-synchronize.md)** — just the instruction block, no explanation.

## The Problem

Start the container, `sleep(5)`, run the migration. Kick off the indexing job, `await delay(2000)`, query the index. Save the record, wait 500ms, fire the webhook so the consumer "has time" to see the row. Every one of these encodes the same statement: "the other operation will finish within N." That statement is false on a loaded CI runner, false on a cold cache, false on a busy Tuesday — and when it's false, the code proceeds against a world that isn't ready and fails somewhere downstream of the actual cause. Meanwhile, every time the statement is *true*, you paid the full N in latency anyway: sleeps are simultaneously too short and too long.

AI assistants reach for sleeps because they work on the first run. The assistant adds `sleep(1)`, the flake disappears, the task completes, and a race condition has been successfully converted into a slower race condition. It's the most reinforced wrong move in concurrent programming: the feedback is immediate and positive, and the failure is deferred to someone else's machine. Sleeps in tests are the gateway form — "wait for the UI to update" — and they metastasize from there into application code, deploy scripts, and worker pipelines.

A sleep is a bet about someone else's latency. The fix is always the same: stop betting, and wait for the actual event.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Sleep to Synchronize

NEVER use a sleep, delay, or pause to wait for another operation to complete. Wait on the operation itself: its promise, its completion event, its readiness check. A sleep is a guess about timing; under load the guess is wrong, and when it's right you paid for it in latency.

- If you can await it, await it: the task's promise/future/join handle. The need to sleep usually means a handle was dropped — recover the handle, don't paper over its absence.
- If completion is signaled, wait on the signal: condition variables, events, channels, `waitForSelector`, readiness probes — wait *for the condition*, with a timeout as failure detection.
- If you can only observe state, poll the condition with backoff and a deadline: `until(() => jobStatus() === 'done', { timeout })`. Polling a real condition is honest; sleeping a fixed time is hoping.
- In tests, the rule is absolute: wait for the element/state/event with the framework's built-in waiting, never `sleep(2000)`. Sleep-based tests are flaky on CI by design and slow everywhere by construction.
- A retry loop with backoff around the *dependent operation* beats a pre-sleep: attempt, and on "not ready," back off and retry. The system tells you when it's ready by succeeding.
- The only legitimate sleeps are ones where the duration itself is the requirement: rate limiting, backoff between retries, scheduled cadence. If removing the sleep would cause a *correctness* failure rather than a pacing change, it's synchronization in disguise.

**Red flags that you're about to violate this:**
- "Two seconds is plenty of time for that to finish."
- "Adding a sleep fixed the flaky test."
- "There's no way to know when it's done." (There's status, an event, or a retry — look harder.)
- "I'll make the sleep longer to be safe." (Now it's slow *and* still a guess.)
- "It's just for the demo/CI/this one script."

---

## Why It Works

1. **It reclassifies sleep-fixes as race-preservation:** the flake didn't go away, its reproduction threshold moved, and naming that breaks the immediate-positive-feedback loop that trains sleeps in.
2. **The handle/signal/poll hierarchy gives a concrete replacement at every information level,** so "there was nothing to wait on" stops being available as an excuse.
3. **The duration-is-the-requirement test cleanly separates legitimate sleeps** (backoff, rate limits) from synchronization sleeps, so the rule can be enforced without exceptions swallowing it.
4. **Deadline-bounded waiting converts timing failures from silent corruption into loud, attributable timeouts** at the point of dependency, not three steps downstream.

## Origin

A deploy pipeline started a database container, slept ten seconds, and ran migrations. It worked for two years, until a base-image update added twelve seconds to startup, and migrations began failing on roughly every third deploy with connection-refused — but only on the busiest runner. Three engineers independently "fixed" it by raising the sleep (fifteen, then twenty, then thirty seconds), adding fifty slow seconds to every deploy before someone replaced the whole arrangement with a five-line wait-until-the-port-accepts-connections loop that completed in under two.
