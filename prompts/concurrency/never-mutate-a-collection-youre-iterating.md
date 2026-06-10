---
title: Never Mutate a Collection You're Iterating
slug: never-mutate-a-collection-youre-iterating
category: concurrency
tags: [universal, concurrency, state]
works_with: all
severity: high
one_liner: "Stops mid-iteration mutation of collections from corrupting traversals"
---

# Never Mutate a Collection You're Iterating

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from iterating a shared collection while it (or another task) mutates it, producing skipped elements, ConcurrentModificationExceptions, and traversals of a structure that no longer exists.

**[Copy-paste ready version](../../install/never-mutate-a-collection-youre-iterating.md)** — just the instruction block, no explanation.

## The Problem

The AI loops over `activeSessions` to broadcast a message; one recipient's send fails, and the error handler removes that session from `activeSessions` — the same map the loop is walking. In Java that's a `ConcurrentModificationException` if you're lucky. In Python it's `RuntimeError: dictionary changed size during iteration`, also if you're lucky. Unlucky looks worse: JavaScript will silently skip the element after a removed index; Go will panic on concurrent map access or, with a plain slice, just compute garbage. And when the mutation comes from *another* task — a cleanup goroutine pruning the map while a request iterates it — the failure isn't even deterministic enough to produce the same exception twice.

This is a default behavior because the loop-and-modify shape is locally reasonable: "go through the items, remove the bad ones" is exactly how a person describes the task. The AI writes the description directly as code. With a small test collection and no concurrent writers, it even works — many runtimes only detect the violation probabilistically, and skipped-element bugs need the removal to land at a specific index to be visible at all.

The async version is sneakier: `for item of queue { await process(item) }` while other tasks push and shift the same array. Each `await` is a window for the collection to change shape under the loop's feet.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Mutate a Collection You're Iterating

NEVER add to or remove from a collection while iterating it — neither in the loop body, nor in anything the loop body calls, nor from another task while the iteration runs.

Iterators assume a frozen structure; mutation mid-walk yields skipped elements, runtime exceptions, or silent garbage depending on the language's mood.

- Filter, don't remove-in-place: `items = items.filter(keep)` / a new list comprehension, instead of deleting inside the loop.
- If you must mutate the original, collect the changes first: gather `toRemove` during iteration, apply after the loop ends.
- Iterating shared state in concurrent code: take a snapshot first — `for s of [...sessions]`, `list(d.items())`, copy under a brief lock — then iterate the snapshot. Accept that the snapshot can be momentarily stale; that's the contract, make the body tolerate it (an entry may be gone by the time you touch it).
- Watch the indirect path: the loop body calls `handleError()`, which calls `unsubscribe()`, which mutates the collection. Mutation through three frames of helpers still counts.
- Async loops over shared collections: every `await` inside the loop is an opportunity for another task to mutate it. Snapshot before the loop, or use a structure designed for it (a proper queue/channel, `ConcurrentHashMap` with its documented weakly-consistent iteration).
- Language-specific safe tools exist — `iterator.remove()` in Java, `retain`/`drain_filter`-style APIs — use them only when they're explicitly documented for the job.

**Red flags that you're about to violate this:**
- "I'll just remove it right here, it's one element."
- "Nothing else touches this list." (The cleanup task does.)
- "It worked on my test data." (Detection is probabilistic; small inputs rarely trip it.)
- "The remove happens in a callback, not in the loop itself."
- "Copying the collection first is wasteful."

---

## Why It Works

1. **Snapshot-then-iterate is a structural fix:** once the loop walks a private copy, no interleaving of writers can break the traversal, so correctness stops depending on timing.
2. **It extends the rule through call chains,** catching the common real-world shape where the mutation hides two helpers deep and the loop looks innocent.
3. **It names the await-window problem,** which turns "single-threaded JS can't have this bug" — a false comfort the AI holds — into a checkable claim about what runs during each await.
4. **It pre-authorizes staleness,** so the AI doesn't respond to the snapshot's weaker guarantee by reverting to live iteration "for freshness."

## Origin

A websocket hub iterated its clients map to broadcast, and the send-failure path removed dead clients from the same map. Under normal churn it threw occasionally and got wrapped in a try/catch ("flaky library"). During a network blip that killed a third of the connections at once, the iteration skipped live clients standing next to dead ones, and a market-data feed silently stopped updating for a subset of users while the server logged nothing but successes. Snapshot-then-broadcast, with removals queued for after the loop, was a six-line fix discovered three incidents late.
