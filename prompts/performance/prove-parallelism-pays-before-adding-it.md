---
title: Prove Parallelism Pays Before Adding It
slug: prove-parallelism-pays-before-adding-it
category: performance
tags: [universal, performance]
works_with: all
severity: medium
one_liner: "Stops thread pools and worker fan-outs bolted onto code nobody measured"
---

# Prove Parallelism Pays Before Adding It

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from reaching for thread pools, multiprocessing, and worker fan-outs as a first move, before knowing whether the workload can benefit at all.

**[Copy-paste ready version](../../install/prove-parallelism-pays-before-adding-it.md)** — just the instruction block, no explanation.

## The Problem

Ask an AI to speed up a batch job and there's a strong chance the answer is a `ThreadPoolExecutor`, a worker pool, or a `Promise.all` fan-out — before anyone established what the job spends its time on. Parallelism is the most dramatic-looking optimization, so it's the one assistants reach for first. But it only pays when the work is actually divisible, the bottleneck has spare capacity, and the serial fraction is small. Parallelize a job that's bottlenecked on one database and you get the same throughput with connection-pool exhaustion as a bonus. Throw eight threads at CPU-bound Python and the GIL serializes them back. Fan out 200 concurrent calls to an API with a rate limit and you've automated getting 429s.

The deeper cost is what parallelism does to the code: nondeterministic ordering, shared-state hazards, partial-failure semantics, harder debugging, and a result-aggregation layer — all permanent complexity, purchased before anyone checked whether a simple fix (batching the I/O, fixing a quadratic, adding the missing limit) would have made the serial version fast enough.

A 4x speedup from threads is also frequently a consolation prize. The profile often shows a 50x win sitting in a per-item network call that should have been one batch request, with zero added complexity. Parallelism-first means never finding that out.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Prove Parallelism Pays Before Adding It

NEVER add parallelism (thread pools, multiprocessing, worker fan-out, mass concurrent awaits) as a first-resort speedup. Parallelism is the last optimization, applied after the serial version is efficient and a measurement shows the workload can actually use concurrent capacity. It buys at most N times speedup and costs nondeterminism, shared-state hazards, and partial-failure handling forever.

- First identify the bottleneck of the *serial* version: CPU, disk, network latency, or a remote service. Parallelism only helps when the bottleneck has idle capacity (e.g., latency-bound I/O). If the job saturates one database or one rate-limited API, more workers add contention, not throughput.
- Exhaust the cheap wins first: batch the per-item calls, fix the quadratic, hoist the repeated work, add the missing limit. A profiler-found algorithmic fix routinely beats the best-case parallel speedup and adds no complexity.
- Know the platform ceilings before proposing: CPU-bound work in GIL-bound Python gains nothing from threads; processes have serialization overhead; event-loop runtimes parallelize I/O waits, not computation.
- If parallelism is justified, bound it: an explicit concurrency limit chosen against the downstream's capacity (connection pool size, rate limit), never unbounded `Promise.all` over a user-sized list.
- Prove it paid: measure serial-optimized vs parallel on realistic input and report both numbers, plus the downstream's error/429 rate during the parallel run. If the speedup is under ~2x or the downstream degraded, prefer the serial version.

**Red flags that you're about to violate this:**
- "This loop is slow, so I'll process items concurrently."
- "Promise.all on everything is the easy win here."
- "More workers means more throughput." (the database disagrees)
- "Threads will help even though it's CPU-bound Python."
- "We can tune the concurrency limit later."
- "Parallel code shows we took performance seriously."

---

## Why It Works

1. **It re-orders the toolbox.** Declaring parallelism the *last* resort, with batching/algorithmic fixes enumerated ahead of it, redirects the AI's first move toward the changes with better payoff-per-complexity.
2. **It demands a bottleneck diagnosis.** "Does the bottleneck have idle capacity?" is the question that decides whether concurrency can help at all, and forcing it converts a reflex into an analysis.
3. **It caps the upside on the record.** "At most N times, costs forever" makes the trade explicit, so a 1.4x measured gain stops looking like a win.
4. **It requires the comparative number.** Measuring serial-optimized vs parallel — not original vs parallel — prevents the common sleight of hand where parallelism gets credit for a speedup that batching alone would have delivered.

## Origin

A report generator took 30 minutes, and the first fix shipped was an eight-worker process pool, which brought it to 24 minutes and introduced an intermittent duplicate-row bug from a shared counter. Weeks later someone finally profiled the serial version: 92% of runtime was a per-row currency-conversion HTTP call. Replacing it with one bulk rates fetch took the *serial* job to 90 seconds. The worker pool and its locking were deleted in the same PR, and the duplicate-row bug closed itself.
