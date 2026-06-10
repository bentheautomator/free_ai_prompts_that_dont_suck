---
title: Cap Unbounded Growth in Long-Lived State
slug: cap-unbounded-growth-in-long-lived-state
category: performance
tags: [universal, performance, memory]
works_with: all
severity: critical
one_liner: "Stops global maps and history arrays that grow forever until the process dies"
---

# Cap Unbounded Growth in Long-Lived State

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from appending to long-lived collections (registries, history lists, dedupe sets, per-user maps) with no eviction, guaranteeing an eventual out-of-memory crash.

**[Copy-paste ready version](../../install/cap-unbounded-growth-in-long-lived-state.md)** — just the instruction block, no explanation.

## The Problem

The pattern looks responsible: a module-level `seenIds = new Set()` to deduplicate webhooks, a `requestHistory` array for debugging, a `Map` of per-session state keyed by session ID, a metrics dict that gains a key per unique URL. Each insert is tiny. Nothing ever removes anything. In a process that restarts daily, nobody notices. In a process that runs for three weeks, the set holds forty million IDs, the heap is at the container limit, GC pauses stretch to seconds, and then the OOM killer ends the discussion — usually at peak traffic, because that's when growth is fastest.

AI assistants write this because the immediate task ("don't process duplicates," "track recent requests") is solved by the insert, and removal serves no test. Eviction is a lifecycle concern, and lifecycle is invisible in the function being written. Worse, the bug is structurally identical to correct code: a `Set` and an `add()` are exactly what you'd write on purpose, minus the part that keeps it finite.

Note this is broader than caches. A cache without bounds is one species (covered by its own rule); this rule covers every long-lived accumulator — dedupe sets, audit trails, retry queues, label sets on metrics, connection registries — anything that only ever gains entries in a process designed to run indefinitely.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Cap Unbounded Growth in Long-Lived State

NEVER add entries to a collection that outlives the request (module-level, global, singleton, long-lived class field) without a mechanism that removes them. In a long-running process, a collection with inserts and no evictions is a scheduled out-of-memory crash; only the date is unknown.

This covers every long-lived accumulator, not just caches: dedupe sets, history/audit arrays, per-session or per-user maps, retry queues, metric label sets, connection registries.

- For every insert into long-lived state, write down what removes the entry: TTL expiry, max-size with eviction, deletion on session end/disconnect, or periodic pruning. "Nothing" is not an answer; pick one and implement it in the same change.
- Keyed-by-unbounded-input is the danger sign: keys from user IDs, URLs, request IDs, or external events grow with traffic, not with code. A map keyed by a small fixed enum is fine; a map keyed by anything callers control is not.
- For dedupe and rate-limit state, bound the window: keep IDs for N minutes or keep the last N entries, not forever. Exact-forever dedupe of an infinite stream requires infinite memory by definition.
- Tie per-entity state to the entity's end-of-life: delete the session entry on logout/expiry, drop the connection record on close, including the error paths.
- Verify under sustained load, not a single pass: run the realistic flow for thousands of iterations and confirm collection sizes and heap plateau instead of climbing. A linear memory-vs-time chart is a failed test.

**Red flags that you're about to violate this:**
- "Each entry is only a few bytes."
- "The process gets redeployed often enough."
- "I'll add eviction once it becomes a problem."
- "We need to remember every ID or dedupe might miss one."
- "Memory is cheap."
- "It's not a cache, so the cache-bounding rule doesn't apply."

---

## Why It Works

1. **It makes removal a required field of insertion.** Asking "what removes this entry?" at write time converts an invisible lifecycle omission into a blank the AI must fill before the code is complete.
2. **It gives a mechanical danger test.** "Is the key controlled by callers or by code?" is decidable from the source alone and flags exactly the collections that scale with traffic.
3. **It kills the small-entry alibi with arithmetic.** Entries times retention equals footprint; naming "inserts with no evictions equals scheduled OOM" frames forever-growth as a certainty rather than a risk.
4. **It defines the plateau test.** "Heap flattens under sustained load" is an observable acceptance criterion that a happy-path unit test cannot fake.

## Origin

A queue consumer kept a module-level set of processed message IDs "to guarantee exactly-once handling." Throughput was about two million messages a day. The service ran fine for nineteen days, then entered a crash loop: OOM kill, restart with an empty set, reprocess the backlog, OOM again, faster each cycle as the backlog grew. On-call burned a weekend before someone graphed heap against uptime and saw a perfectly straight line. The fix was a TTL'd window of the last hour of IDs, which is all the dedupe ever actually needed.
