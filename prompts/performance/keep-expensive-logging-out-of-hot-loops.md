---
title: Keep Expensive Logging Out of Hot Loops
slug: keep-expensive-logging-out-of-hot-loops
category: performance
tags: [universal, performance, loops]
works_with: all
severity: high
one_liner: "Stops per-item log lines and debug serialization from dominating hot paths"
---

# Keep Expensive Logging Out of Hot Loops

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from putting per-item log statements and eagerly-serialized debug payloads inside hot loops, where the logging outweighs the work.

**[Copy-paste ready version](../../install/keep-expensive-logging-out-of-hot-loops.md)** — just the instruction block, no explanation.

## The Problem

AI assistants are generous loggers — it reads as diligence. Asked to process a million records, they'll produce a loop with `logger.info(f"Processing record {record.id}: {record.to_dict()}")` inside it. That's a million log lines: a million string interpolations, a million dict serializations, a million write syscalls contending on one stream, gigabytes of disk, and a log aggregator bill that arrives like a plot twist. The actual per-record work might be 50 microseconds; the log line costs more than the job.

The subtler version burns CPU even when nothing is logged at all. `logger.debug("state: " + json.dumps(big_object))` builds the full string *before* the logger checks whether debug is enabled — in most logging frameworks, arguments are evaluated eagerly. Production runs at INFO, the line emits nothing, and the process still pays for a JSON serialization per iteration. Profiles of "mysteriously slow" pipelines regularly show double-digit percentages inside logging calls that never produced a byte of output.

Assistants do this because logging is the one side effect that's always praised and never measured: more logs look like more observability. Per-item granularity also feels proportionate when you're writing the loop body and can't see the iteration count from there.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Keep Expensive Logging Out of Hot Loops

NEVER put per-iteration log statements or eagerly-built debug payloads inside loops or code paths that run per item at data scale. At a million iterations, the logging is the workload: interpolation, serialization, and write syscalls multiplied by n, plus the storage and ingestion bill downstream.

- Log per batch, not per item: progress every N items or T seconds ("processed 50,000/1,200,000"), plus a summary at the end (counts, durations, failure totals). Per-item detail belongs on the *failure* path, where volume is low and value is high.
- Never build log payloads eagerly at levels that may be disabled. `logger.debug("x=" + json.dumps(obj))` serializes even when debug is off. Use lazy forms: `logger.debug("x=%s", obj)` (formats only if enabled), `isEnabledFor`/`isDebugEnabled` guards around anything costly, or lambda/supplier APIs where the framework has them.
- Don't serialize entire objects into hot-path logs; log the identifier and the few fields that matter. The 4KB context dict per request is a cost at every layer: CPU, network, storage, ingestion pricing.
- Watch synchronous log writes in hot request paths: a blocking write to a contended stream or slow disk stalls the path itself. High-volume services need buffered/async handlers, which is a deliberate configuration choice, not a default.
- Verify two ways: profile the hot path and check the logging framework's share of CPU (more than a few percent is a finding), and estimate volume — iterations times bytes per line — before shipping. A million 200-byte lines is 200MB per run; say that number out loud first.

**Red flags that you're about to violate this:**
- "More logging means better observability."
- "It's only a debug line, it's off in production." (the f-string still runs)
- "Logging is basically free."
- "Per-item logs will help if something goes wrong."
- "I'll log the whole object so we have full context."
- "We can always lower the log level later."

---

## Why It Works

1. **It reprices logging as workload.** The AI treats log statements as cost-free observability; "multiplied by n, plus the ingestion bill" attaches a unit price the AI can compute at the loop boundary.
2. **It exposes eager evaluation.** The disabled-level-still-pays mechanism is invisible at the call site; naming it converts "it's only debug" from a defense into a recognized trap.
3. **It redirects detail to the failure path.** Batch-progress-plus-failure-detail satisfies the observability instinct that motivates over-logging, so the rule works with the AI's diligence rather than against it.
4. **It demands the volume estimate up front.** "Iterations times bytes, say the number" makes the absurd cases (200MB of logs per run) self-refuting before they ship.

## Origin

A data pipeline's nightly run crept from 40 minutes to 5 hours over two months, and the team hunted phantom database regressions for weeks. The profiler finally showed 71% of CPU inside the logging framework: a per-row `logger.debug` with an f-string that serialized the full row context — at INFO level in production, emitting nothing, paying everything. Two changes (lazy formatting, progress-every-10k-rows) returned the run to 38 minutes. The log aggregator invoice from staging, where debug was enabled, had been trying to tell them for weeks; it just hadn't been opened.
