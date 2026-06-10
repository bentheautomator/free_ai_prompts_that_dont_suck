---
title: Cap Concurrency on Parallel Fan-Out
slug: cap-concurrency-on-parallel-fan-out
category: backend
tags: [universal, backend]
works_with: all
severity: high
one_liner: "Stops Promise.all over ten thousand items from DDoSing your own stack"
---

# Cap Concurrency on Parallel Fan-Out

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents unbounded parallel fan-out — `Promise.all` over every item — from overwhelming dependencies, pools, and your own process.

**[Copy-paste ready version](../../install/cap-concurrency-on-parallel-fan-out.md)** — just the instruction block, no explanation.

## The Problem

Somewhere between "do it in a loop" (too slow) and "do it with bounded concurrency" (correct) sits the assistant's favorite move: `await Promise.all(items.map(item => callApi(item)))`. Or `asyncio.gather(*tasks)`. Or spawning a goroutine per element. It reads as idiomatic, it's dramatically faster than sequential, and over the 20-item dev dataset it is genuinely fine. The code contains no number that says how many requests fly at once — because the answer is "all of them," and *all* is decided later, by production data.

When `items` is 10,000, the code launches 10,000 simultaneous requests. Several things break at once: the target service gets a ten-thousand-request spike from a single caller (you've built a DDoS tool with extra steps, and if the target rate-limits you, every one of those gets a 429 and your retry logic makes it worse); your own side exhausts sockets, file descriptors, or the database pool the calls share; and memory balloons holding ten thousand in-flight requests and their pending results. Bonus failure: `Promise.all` rejects on the first error, abandoning 9,999 in-flight operations with no record of which completed.

Assistants do this because unbounded gather is the shortest "parallel" idiom in every language, and nothing about a 20-element test hints that cardinality is an input controlled by the future.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Cap Concurrency on Parallel Fan-Out

NEVER launch parallel work whose concurrency equals the input size. `Promise.all(items.map(...))`, `gather(*all_tasks)`, or a goroutine per element means production data decides your parallelism. Always run fan-out through an explicit concurrency limit.

- Use a bounded executor: a worker-pool/limit utility (`p-limit`, `p-map` with `{concurrency: N}` in Node), `asyncio.Semaphore` around each task in Python, a semaphore or worker-pool of N goroutines reading from a channel in Go, `errgroup.SetLimit(n)`.
- Pick the limit from the bottleneck, not vibes: respect the target's documented rate limit, your connection pool size, and per-host socket limits. Single digits to low tens is the usual answer for external APIs; defaulting to something like 10 beats defaulting to ∞.
- Make the limit a named constant or config value so load tests and incidents can tune it without a code hunt.
- Handle partial failure deliberately: use `Promise.allSettled` / collect per-item results rather than first-error-aborts-everything, and report which items failed so the batch can be partially retried.
- Compose with your other limits: each parallel call still needs a timeout, and retries inside fan-out must be jittered — N parallel naive retries is the storm with a head start.
- If items number in the hundreds of thousands, fan-out in the request path is the wrong tool entirely — enqueue the work for background workers instead.

**Red flags that you're about to violate this:**
- "Promise.all is the idiomatic way to parallelize."
- "There are only ever a few items in this list." (Enforced where?)
- "More concurrency means it finishes faster." (Until the rate limiter, pool, or kernel disagrees.)
- "Goroutines are cheap, spawn one per row."
- "The downstream service can handle it, it's internal."
- "I'll deal with failures by letting the whole batch throw."

---

## Why It Works

1. **It surfaces the hidden parameter.** Unbounded gather has a concurrency setting — it's just set to `len(input)` by omission. Forcing an explicit N turns an accident of data into an engineering decision with a rationale.
2. **It protects both directions.** The cap simultaneously shields the target (spike becomes a steady stream under its rate limit) and the caller (sockets, memory, and shared pools stay within budget) — one mechanism, two outages prevented.
3. **It fixes failure semantics alongside throughput.** First-error-aborts is the silent second bug in `Promise.all`; per-item results make partial completion a tracked state instead of a mystery.
4. **It composes with timeout and retry rules.** Fan-out multiplies whatever behavior each call has; capping N bounds the multiplier so one bad dependency costs N hung slots, not one per item.

## Origin

A sync feature refreshed product data by mapping `Promise.all` over a merchant's catalog. Most merchants had dozens of products; then an enterprise merchant with 38,000 SKUs clicked "sync now." The supplier's API rate-limited the burst, every 429 was retried without jitter, the service's outbound socket pool drained, and unrelated endpoints started timing out — all from one button press by one customer. The fix was `p-limit(8)` and `allSettled`; sync now takes four minutes, completes, and nobody else notices it running.
