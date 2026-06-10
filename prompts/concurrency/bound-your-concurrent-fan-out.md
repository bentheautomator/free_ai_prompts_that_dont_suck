---
title: Bound Your Concurrent Fan-Out
slug: bound-your-concurrent-fan-out
category: concurrency
tags: [universal, concurrency, resources]
works_with: all
severity: high
one_liner: "Stops unbounded Promise.all fan-outs from DoS-ing your own dependencies"
---

# Bound Your Concurrent Fan-Out

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from launching one concurrent operation per item of an unbounded list, turning "process these in parallel" into a self-inflicted denial of service.

**[Copy-paste ready version](../../install/bound-your-concurrent-fan-out.md)** — just the instruction block, no explanation.

## The Problem

`await Promise.all(users.map(u => sendEmail(u)))` is correct, idiomatic, and a weapon. With 50 users it's parallelism; with 80,000 it's 80,000 simultaneous SMTP connections — or 80,000 open sockets, 80,000 pool-acquisition attempts against a pool of 10, or a third-party API watching you arrive all at once and responding with 429s, then with a ban. The process itself suffers too: every in-flight operation holds buffers and file descriptors, so the big fan-out lands as OOM kills and `EMFILE` errors that look nothing like "the list got long." The code didn't change between working and exploding; the *input size* did.

AI assistants write unbounded fan-outs because the map-then-all shape is the canonical "do it in parallel," and the collection in the example was always small. Concurrency limit is a parameter the snippet never had, so the AI never thinks to add it. Tests run with five fixture items and confirm the logic; nothing in any test exercises the property that breaks, which is the *width* of the fan-out under production-sized input.

The fix is one concept: parallelism is a dial, not a boolean. Somewhere between 1 (the sequential-awaits mistake) and N (this mistake) is a number chosen on purpose.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Bound Your Concurrent Fan-Out

NEVER launch one concurrent operation per element of a collection whose size you don't control. Parallel work over a list runs through a concurrency limit chosen on purpose.

`Promise.all(items.map(work))` makes the input length your concurrency level; at production sizes that's an attack on your own dependencies.

- Use a bounded executor: `p-limit`/`p-map` with a limit in Node, `asyncio.Semaphore` around the task body in Python, a worker pool of K goroutines pulling from a channel in Go, `Parallel.ForEachAsync` with `MaxDegreeOfParallelism` in C#. The shape is N items flowing through K lanes.
- Pick K from the bottleneck, not from vibes: smaller than your connection pool, within the target's rate limit, sized to per-operation memory. Single digits to low tens is the usual right answer; make it a named constant or config so load testing can tune it.
- Check whether each item's work *internally* fans out too — K outer times M inner is K×M concurrent calls on the dependency. Budget the product, not the factor.
- Unbounded inputs deserve streaming: for very large or paginated collections, process as a pipeline (read K ahead, process K wide) rather than materializing all tasks up front — the task objects alone can OOM you before any I/O happens.
- Failure policy still applies at any width: decide fail-fast vs collect-all (`allSettled`), and make sure one item's failure doesn't strand the semaphore (release in `finally`).
- Spawning one thread per item is the same bug with heavier ammunition; thread pools exist for the same reason.

**Red flags that you're about to violate this:**
- "Promise.all on the mapped array is the standard pattern."
- "The list is usually small." (Usually. The incident is the other day.)
- "More parallelism is faster, why throttle ourselves?"
- "The downstream service can handle load; that's their problem." (Their 429s and your ban are your problem.)
- "I'll add a limit if we ever hit issues." (The issue arrives as an outage, not a warning.)

---

## Why It Works

1. **It exposes the hidden coupling** — input length silently *is* the concurrency level in map-then-all — which is invisible at the call site and the entire mechanism of the failure.
2. **Named limiter tools make compliance cheaper than violation:** `p-limit(10)` or a semaphore is one line, so the rule survives contact with deadline pressure.
3. **"Budget the product" catches nested fan-outs,** the variant that defeats teams who bounded the outer loop and still took down the dependency.
4. **Small fixtures structurally cannot test width,** so the rule supplies at write time the constraint that no green test suite will ever supply.

## Origin

A nightly job re-rendered thumbnails: map every image to an async resize, `Promise.all`, ship it. At 2,000 images it had run for months. A bulk customer import brought the catalog to 600,000; that night the job opened sockets until the host hit its file-descriptor limit, the shared image-processing service tipped over, and the on-call for *that* service got paged for what was, from their side, a DDoS from a friendly IP. A semaphore of 16 made the job slower by twenty minutes and made it finish, which the unbounded version never did.
