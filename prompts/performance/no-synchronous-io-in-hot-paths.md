---
title: No Synchronous I/O in Hot Paths
slug: no-synchronous-io-in-hot-paths
category: performance
tags: [universal, performance, io]
works_with: all
severity: critical
one_liner: "Stops blocking file and network calls inside request handlers and hot loops"
---

# No Synchronous I/O in Hot Paths

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from dropping blocking file, network, or DNS calls into request handlers and hot loops, where one slow call stalls everything behind it.

**[Copy-paste ready version](../../install/no-synchronous-io-in-hot-paths.md)** — just the instruction block, no explanation.

## The Problem

One `fs.readFileSync` inside an Express route handler. One `requests.get()` inside an async FastAPI endpoint. One synchronous DNS lookup per message in a consumer loop. In a single-threaded event loop, a blocking call doesn't just slow its own request — it freezes the entire process for the duration. Every concurrent request, every timer, every health check waits behind that one disk read. A 20ms sync read at 200 requests per second means the event loop spends four full seconds of every ten blocked, and p99 latency goes somewhere obscene. In threaded servers it's gentler but still ugly: each blocking call pins a worker, and the pool drains under load.

AI assistants write sync I/O in hot paths because the sync form is shorter, appears constantly in scripts and tutorials, and works flawlessly in every local test, where there is exactly one request and the disk is an SSD with no contention. `readFileSync` and `readFile` produce identical results in a demo. The difference only exists under concurrency, which the assistant never experiences.

The especially sneaky variant: a synchronous call buried inside an `async` function. The signature promises non-blocking; the body holds the event loop hostage anyway. Reviewers see `async` and move on.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No Synchronous I/O in Hot Paths

NEVER perform blocking I/O (file reads/writes, HTTP calls, DNS lookups, subprocess waits, sleeps) inside a request handler, event-loop callback, message-consumer loop, or any code that runs per request or per item. A blocking call in shared execution context stalls every request behind it, not just its own.

In event-loop runtimes (Node, Python asyncio) one sync call freezes the whole process for its duration; in threaded servers it pins a worker and drains the pool under load.

- Use the async form in the hot path: `fs.promises.readFile` not `readFileSync`, `httpx.AsyncClient`/`aiohttp` not `requests`, async DB drivers not blocking ones. In async code, a library without an async API belongs in a thread/executor offload (`asyncio.to_thread`, worker pool), not inline.
- `async def` does not make its body non-blocking. Audit what's inside: `requests.get`, `time.sleep`, `open().read()`, and sync ORM calls block the loop regardless of the function's signature.
- Sync I/O is fine at startup, in CLI scripts, in build tooling, and in one-shot batch code with no concurrency. The rule is about per-request and per-item paths, not a global ban.
- Never put `sleep` (the blocking kind) in a hot path for pacing or retry backoff; use the runtime's async delay.
- Verify under concurrency, not in isolation: fire 50 parallel requests at the path and compare p99 to the single-request latency. If concurrent latency degrades far beyond the single-call cost, something is blocking. Event-loop lag metrics and `blocked-at`-style tooling will name the line.

**Red flags that you're about to violate this:**
- "The sync version is one line and the file is tiny."
- "It's already inside an async function, so it's non-blocking."
- "This call only takes a few milliseconds."
- "requests is simpler than setting up an async client."
- "It worked fine when I tested the endpoint." (alone, once)
- "The config file read is fast on my machine."

---

## Why It Works

1. **It states the shared-fate mechanism.** The AI models a blocking call as costing its own caller; "stalls every request behind it" reprices the same call at process scope, which is what actually makes it critical.
2. **It explodes the async-signature illusion.** Naming `async def` with a blocking body as a specific trap catches the variant that passes human review most often.
3. **It scopes the rule honestly.** Permitting sync I/O in scripts and startup prevents the over-correction (async-everything in a CLI tool) that would teach the AI to ignore the rule.
4. **It tests with concurrency.** "50 parallel requests, compare p99" measures the only condition under which the bug exists, so the verification can't pass by accident.

## Origin

A Node API loaded a feature-flag JSON with `readFileSync` inside the request handler "so flags are always fresh," a four-millisecond read. Under normal traffic nobody noticed. During a marketing-driven spike to 600 rps, the event loop was blocked roughly 2.4 seconds out of every second of work, latency went vertical, health checks timed out, and the orchestrator helpfully restarted every pod in a rolling loop. Total outage: 40 minutes. The patch was the async read plus a 5-second in-memory refresh, and the incident review's first slide was just the word "Sync" in 200-point font.
