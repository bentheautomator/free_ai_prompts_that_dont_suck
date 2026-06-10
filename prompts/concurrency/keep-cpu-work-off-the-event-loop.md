---
title: Keep CPU Work Off the Event Loop
slug: keep-cpu-work-off-the-event-loop
category: concurrency
tags: [universal, concurrency, async]
works_with: all
severity: high
one_liner: "Stops sync CPU work from freezing every other request on the event loop"
---

# Keep CPU Work Off the Event Loop

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from running heavy synchronous computation inside async handlers, where it freezes the entire process for every concurrent user.

**[Copy-paste ready version](../../install/keep-cpu-work-off-the-event-loop.md)** — just the instruction block, no explanation.

## The Problem

Single-threaded async runtimes (Node, Python asyncio) run all concurrency on one thread, and the deal is strict: every task yields quickly, or nobody runs. The AI breaks the deal casually — it parses a 50MB JSON upload with `JSON.parse`, resizes an image, computes a bcrypt hash, zips a directory, or runs a tight loop over a million rows, all inline in an async handler. The function is marked `async`, so it looks cooperative. It isn't: between awaits it's just code, and for the 900ms that the parse runs, every other request in the process is frozen. Health checks time out, websockets miss pings, and the load balancer starts killing your healthiest-looking instances.

The AI does this because `async` syntax provides no distinction between "yields here" and "blocks here." `JSON.parse(body)` and `await db.query(...)` sit on adjacent lines with identical innocence. And it benchmarks fine: one developer making one request never observes the freeze, because there's nobody else to starve. The damage is strictly a function of concurrency, which is the one dimension absent from every local test.

Sync-I/O variants count double: `fs.readFileSync`, `execSync`, synchronous DNS, `requests.get` inside an asyncio handler — these block the loop *and* wait on the outside world while doing it.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Keep CPU Work Off the Event Loop

NEVER run heavy synchronous work — CPU-bound computation or blocking I/O — directly inside an async handler on a single-threaded event loop. While it runs, every other request in the process is frozen.

`async` marks where a function *can* yield, not a guarantee that it does; everything between awaits blocks the world.

- Offload CPU-bound work: Node `worker_threads` or a job queue; Python `loop.run_in_executor` / `ProcessPoolExecutor` (threads don't help CPU-bound Python; processes do); never inline in the handler.
- Ban sync I/O in async contexts: `fs.*Sync`, `execSync`, `child_process.spawnSync`, Python `requests`/`time.sleep`/blocking DB drivers inside `async def`. Use the async equivalents (`asyncio.sleep`, async clients) or push to an executor.
- Watch for hidden CPU: parsing/serializing large JSON or XML, compression, encryption and password hashing, image processing, regex over big inputs (catastrophic backtracking blocks too), sorting or transforming very large arrays.
- Big-input loops that must stay inline need explicit yield points (chunk the work, `await setImmediate()` / `await asyncio.sleep(0)` per chunk) — and that's the fallback, not the plan.
- Treat input size as attacker-controlled: a parse that's fine at 100KB is an outage at 100MB. Bound it or offload it.

**Red flags that you're about to violate this:**
- "The function is async, so it won't block anything."
- "It's only ~50ms of CPU." (Times every request, on the only thread you have.)
- "The sync version is simpler and the async one needs a worker."
- "It ran instantly when I tested it." (Alone, with a small input.)
- "Hashing/zipping/parsing isn't really 'heavy computation.'"

---

## Why It Works

1. **It corrects the core misreading of `async`** — the AI treats the keyword as a concurrency guarantee; the rule redefines it as "yields only at awaits," which makes the blocking spans visible.
2. **The named-workload list does the recognition work.** "Heavy CPU" is vague; "bcrypt, JSON.parse on uploads, image resize, regex backtracking" is greppable.
3. **It explains why solo benchmarks are structurally blind:** blocking the loop harms only the *other* requests, and a test with no other requests has no one to harm.
4. **It routes each case to its correct mechanism** (worker, executor, async client, chunked yields) rather than leaving "don't block" as an instruction with no implementation.

## Origin

An export endpoint built a CSV from 400k rows synchronously inside an async route — string concatenation in a loop, about four seconds of pure CPU. Every time a customer clicked Export, the whole instance went silent: health checks failed, the orchestrator restarted the pod mid-export, the customer retried, and the cluster played whack-a-mole with itself for an afternoon. The graphs showed instances dying with low CPU *averages*, because four seconds of 100% on one thread barely moves a one-minute average. The fix was a worker queue and a download link.
