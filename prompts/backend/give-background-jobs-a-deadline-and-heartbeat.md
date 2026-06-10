---
title: Give Background Jobs a Deadline and Heartbeat
slug: give-background-jobs-a-deadline-and-heartbeat
category: backend
tags: [universal, backend, jobs]
works_with: all
severity: high
one_liner: "Stops one hung job from silently occupying a worker slot forever"
---

# Give Background Jobs a Deadline and Heartbeat

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents background jobs with no maximum runtime from hanging forever, eating worker capacity, and looking exactly like jobs that are merely slow.

**[Copy-paste ready version](../../install/give-background-jobs-a-deadline-and-heartbeat.md)** — just the instruction block, no explanation.

## The Problem

A background job an assistant writes has two designed outcomes: success or exception. Production adds a third the code never models: *neither*. The job hangs — wedged on an unkillable external call, deadlocked, looping on pathological input, waiting on a socket that will never speak again. No exception fires, so no retry triggers, no dead-letter routing engages, no alert sounds. From every dashboard's perspective, the job is "running." It will be "running" next week.

The damage compounds quietly. Each hung job permanently occupies a worker slot; with a fixed pool of 10, the eleventh hang stops all background processing — a total outage that no error rate reflects, because nothing is erroring. Before that, throughput just sags mysteriously. And because "stuck" and "slow" are indistinguishable without a deadline, operators can't even safely kill things: is that 4-hour job wedged, or is it the monthly export at 92%?

Assistants omit max runtimes because the happy path terminates by itself, and in dev everything terminates — small data, reliable dependencies, no pathological inputs. Timeouts on individual outbound calls (a separate rule) narrow the window but don't close it: jobs hang in loops, in CPU-bound spins, and in the accumulation of a thousand slow-but-not-timed-out steps. The job as a whole needs its own clock.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Give Background Jobs a Deadline and Heartbeat

Every background job MUST have a maximum runtime, enforced from outside the job's own code, and long-running jobs MUST emit progress heartbeats. A job with no deadline that hangs is invisible: it throws nothing, retries never, and holds its worker slot forever.

- Set an explicit per-job-type timeout in the worker framework (Celery `time_limit`, BullMQ timeouts, a context deadline wrapping the handler in Go) — enforced outside the job, because a wedged job cannot check its own watch.
- Size the deadline from observed runtime (e.g., p99 × 3), not a universal "1 hour to be safe." A deadline that never fires is a deadline you don't have.
- On expiry, kill the job and route it through your normal failure path — retry if transient, dead-letter after max attempts — so "hung" degrades into the failure mode you already handle, instead of a fourth state nobody handles.
- Long jobs should heartbeat: update a `last_progress_at` timestamp or extend a claim lease as batches complete. A sweeper that flags jobs whose heartbeat is stale catches hangs in minutes; a deadline alone catches them at the deadline.
- Alert on both signals: deadline kills (something regressed) and stale heartbeats (something is wedged right now).
- Since deadline kills interrupt mid-work, the job body must be idempotent and resumable — see your idempotency and checkpointing rules, or kills become duplicate side effects.
- Fleet-level tell: worker slots pinned at 100% while throughput falls means hangs are accumulating.

**Red flags that you're about to violate this:**
- "The job finishes in a few seconds, a timeout is pointless."
- "Each HTTP call inside already has a timeout, so the job can't hang." (Loops, deadlocks, and CPU spins disagree.)
- "I'll have the job check elapsed time periodically." (The wedged job checks nothing. Enforce externally.)
- "If it hangs we'll see errors." (Hangs are precisely the absence of errors.)
- "I'll set it to 24 hours so it never kills legitimate work."
- "The framework probably has a default limit." (Check it. It's usually infinity.)

---

## Why It Works

1. **It models the third outcome.** Success/failure code leaves "neither" unhandled; an external deadline forcibly converts "neither" into "failure," which is the state all your retry, DLQ, and alerting machinery already knows how to process.
2. **It enforces from outside the failure domain.** Any in-job check shares the job's fate — a deadlock can't poll a flag. Framework-level kills work precisely because they don't depend on the patient's cooperation.
3. **It splits detection from termination.** Heartbeats give minutes-scale detection of hangs without forcing aggressive deadlines that would kill legitimate long runs; the two knobs tune independently.
4. **It makes "stuck vs. slow" a measurement.** With deadlines sized from p99 and heartbeats showing progress, the 2 a.m. question "can I kill this?" has a data-backed answer instead of a guess.

## Origin

A media platform's video-transcode workers called a processing library that, on certain corrupt uploads, looped forever at 100% CPU — no exception, no timeout, no log line. Each poisoned upload bricked one of sixteen worker slots permanently. Throughput sagged over eleven days as slots filled with zombies; on day twelve the sixteenth corrupt file arrived, and all transcoding stopped while every dashboard showed sixteen jobs healthily "running." Detection took hours because nothing was failing. A 30-minute deadline and a heartbeat sweeper turned the same corrupt file into a dead-letter entry with a stack trace.
