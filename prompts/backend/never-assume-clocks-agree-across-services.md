---
title: Never Assume Clocks Agree Across Services
slug: never-assume-clocks-agree-across-services
category: backend
tags: [universal, backend]
works_with: all
severity: high
one_liner: "Stops cross-machine timestamp math from breaking when clocks drift"
---

# Never Assume Clocks Agree Across Services

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents logic that compares timestamps from different machines from silently breaking when their clocks disagree — which they always, eventually, do.

**[Copy-paste ready version](../../install/never-assume-clocks-agree-across-services.md)** — just the instruction block, no explanation.

## The Problem

Service A stamps an event with its wall clock. Service B receives it and computes `now() - event.timestamp` to measure age, enforce a token's freshness window, or order it against events from service C. An assistant writes this without hesitation, because on a laptop, `now()` is one clock and the arithmetic is exact.

In production, every machine has its own clock, and they disagree — usually by milliseconds, sometimes by seconds, occasionally (a failed NTP daemon, a VM resumed from snapshot, a container with a stale base image) by minutes or years. Clocks also step *backwards* when NTP corrects them. Every piece of cross-machine clock math inherits these errors: events age negative, "expires in 30 seconds" tokens are dead on arrival or immortal, latency metrics go negative or spike to nonsense, last-write-wins picks the loser, and a cache entry written "now" is judged expired by the node that reads it. The bugs are intermittent, environment-specific, and they un-reproduce themselves when the clock re-syncs.

Assistants write clock-comparison logic because timestamps look like plain numbers and subtraction looks like math. The fact that the two numbers came from two different instruments measuring two slightly different realities is nowhere in the type system.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Assume Clocks Agree Across Services

NEVER write logic whose correctness depends on two machines' clocks agreeing, or on one machine's clock never jumping. Clocks drift, skew, and step backwards under NTP correction; any cross-service timestamp comparison inherits that error.

- Never order events from different producers by their embedded wall-clock timestamps. Use a single authority instead: a sequence from one database (`SERIAL`, one node's monotonic counter), the broker's partition offset, or explicit version numbers.
- For elapsed time within one process, use the monotonic clock (`time.monotonic()`, `process.hrtime()`, Go's `time.Since`), never `now() - then` with wall time — wall time is allowed to jump while you're measuring.
- For expiry and freshness across services, build in tolerance: accept reasonable clock skew on validation windows (as JWT validators do with leeway), and prefer "issued by the same authority that validates" over "issued by clock A, judged by clock B."
- Let one clock decide per decision: use the database's `NOW()` for created/expires columns compared by database queries, rather than mixing application time into database comparisons.
- For deduplication, last-write-wins, and conflict resolution, use versions or vector-ish counters, not timestamps. Two writes 5ms apart on machines skewed 50ms resolve in the wrong order, silently.
- Always store and transmit timestamps in UTC with timezone-explicit types; local-time ambiguity stacks a second error source on top of skew.
- Treat "the timestamps say this is impossible" as expected telemetry (negative durations, future events) — clamp, log, and continue rather than crashing.

**Red flags that you're about to violate this:**
- "Both servers run NTP, their clocks are basically identical."
- "I'll order the events by their timestamps."
- "The token expires in 30 seconds, plenty of margin."
- "A negative duration can't happen, I'll assert against it."
- "I'll compare the API's timestamp against our server's now()."
- "Milliseconds of drift don't matter here." (Until the NTP daemon dies and it's minutes.)

---

## Why It Works

1. **It demotes wall clocks from oracle to estimate.** Once timestamps are framed as readings from disagreeing instruments, the assistant stops using them for decisions that need a single source of truth, and starts using sequences and versions — which are actually authoritative.
2. **It separates the three jobs of time.** Ordering (use sequences), elapsed time (use monotonic), and human-readable record (wall clock is fine) have different correct tools; the conflation of the three is where the bugs live.
3. **It builds skew tolerance into windows.** Freshness checks with zero leeway fail at exactly the skew your fleet actually has; explicit tolerance converts a flaky auth outage into a non-event.
4. **It plans for impossible readings.** Code that asserts "duration >= 0" crashes on the first backwards step; code that clamps and logs survives it and tells you about the broken NTP daemon for free.

## Origin

A session service issued short-lived signed actions stamped by one autoscaling group and validated by another. A bad VM image in one group shipped with NTP disabled; its clock drifted 47 seconds over three weeks. Every action issued by those instances was "expired" on arrival — but only for the fraction of traffic hitting that group, only after the drift exceeded the window, and never reproducible from the office. Three engineers chased a phantom auth bug for days before someone compared `date` output across hosts.
