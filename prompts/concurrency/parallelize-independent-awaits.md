---
title: Parallelize Independent Awaits
slug: parallelize-independent-awaits
category: concurrency
tags: [universal, concurrency, async]
works_with: all
severity: medium
one_liner: "Stops chains of sequential awaits that should run concurrently"
---

# Parallelize Independent Awaits

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from writing `await a(); await b(); await c();` for operations with no dependency on each other, silently summing their latencies instead of overlapping them.

**[Copy-paste ready version](../../install/parallelize-independent-awaits.md)** — just the instruction block, no explanation.

## The Problem

The AI fetches the user, then awaits it. Fetches their orders, then awaits that. Fetches their preferences, then awaits that. Three independent reads, none of which uses the others' results, executed as a chain: 120ms + 200ms + 80ms = 400ms, when the same work overlapped is 200ms. Do this inside a loop over fifty items and a page that should load in a quarter second takes ten. Nothing is "broken," so nobody files a bug; the product is just mysteriously, permanently slow, and the slowness is smeared across every handler instead of concentrated anywhere a profiler would point.

This is the AI's default because sequential awaits are how async code reads in every tutorial, and because in a one-request mental model the order is harmless: the result is identical, only later. Tests pass instantly against local mocks where each await costs microseconds. The structure of the code gives no visual signal that latency is being summed, and `await` on each line *looks* like diligence.

The fix has a real constraint, though: only independent operations may overlap, and partial-failure semantics change (with `Promise.all`, one rejection cancels your interest in the others). The instruction has to demand both the parallelism and the dependency check, or you trade slow-but-correct for fast-but-wrong.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Parallelize Independent Awaits

When you write two or more awaits in sequence, ALWAYS check whether the later operation uses the earlier one's result. If it doesn't, start both before awaiting either.

Sequential awaits on independent operations sum their latencies for no benefit; this is the single most common self-inflicted slowness in async code.

- Wrong: `const user = await getUser(id); const orders = await getOrders(id);`. Right: `const [user, orders] = await Promise.all([getUser(id), getOrders(id)]);` (Python: `asyncio.gather`; C#: `Task.WhenAll`; Go: errgroup or goroutines + WaitGroup).
- A loop of `for (const id of ids) { await fetchItem(id) }` over independent items is the same bug at scale. Map to tasks, then await the batch, with a concurrency bound if the list is large or the target is rate-limited.
- Only parallelize genuinely independent operations. If B reads what A wrote, or B must not happen when A fails, keep them sequential and say nothing more.
- When you parallelize, handle the new failure semantics deliberately: `Promise.all` rejects on first failure; use `Promise.allSettled` / `gather(..., return_exceptions=True)` when you need every result regardless.
- Don't interleave a write with reads "for speed." Writes order the world; reads merely observe it.

**Red flags that you're about to violate this:**
- "I'll just await each one; it's cleaner to read."
- "These calls are fast, sequencing them doesn't matter."
- "Parallelizing means restructuring the error handling, so I'll skip it."
- "The tests run in milliseconds either way."
- "I'll optimize this later if it's slow." (Nobody measures it later.)

---

## Why It Works

1. **It converts a performance instinct into a dependency question** ("does B use A's result?"), which the AI can answer from the code in front of it without profiling anything.
2. **It names the loop variant explicitly,** because the AI that gets `Promise.all` right for two calls will still write the N-sequential-awaits loop unprompted.
3. **It pairs the speedup with its cost** (changed failure semantics, ordering of writes), so the rule can't be over-applied into a correctness bug.
4. **Mock-speed tests can't reveal summed latency** — only structural review can, and the rule is a structural review.

## Origin

A dashboard endpoint awaited eleven independent lookups in a row, each added one at a time over months, each individually "fast." Production latency was 1.9 seconds and everyone blamed the database. The fix was one `Promise.all` and the endpoint dropped to 240ms, the duration of its slowest call. No query changed. The postmortem's only action item was a lint rule, because the team realized every engineer, human and AI, had read past that block fifty times without seeing eleven round trips standing in single file.
