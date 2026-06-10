---
title: Make Read-Modify-Write Atomic
slug: make-read-modify-write-atomic
category: concurrency
tags: [universal, concurrency, races]
works_with: all
severity: critical
one_liner: "Stops lost updates from non-atomic counters, balances, and toggles"
---

# Make Read-Modify-Write Atomic

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from writing read-the-value, change-it-in-memory, write-it-back sequences that lose updates whenever two callers overlap.

**[Copy-paste ready version](../../install/make-read-modify-write-atomic.md)** — just the instruction block, no explanation.

## The Problem

`counter = await getCount(); await setCount(counter + 1);` is the canonical lost update. Two requests read 41 at the same moment, both write 42, and one increment evaporates. The same shape hides under friendlier names: deduct a balance, decrement inventory, append to a JSON column, flip a feature toggle, accumulate a total in a loop of concurrent workers. Each occurrence is two operations wearing a trench coat, pretending to be one.

AI assistants produce this constantly because read-modify-write is the *natural* way to express mutation, and in a single-threaded mental model it's flawless. `x += 1` looks atomic on the page even when `x` is a row in Postgres, a key in Redis, a field in a shared struct, or a React state closure. Every unit test passes because tests mutate alone. The failure rate in production is proportional to contention, so it starts at "weird, the count is off by a little" and grows with traffic into "we sold 300 units of an item with 200 in stock."

The fix is never "be more careful." It's pushing the mutation to wherever it can be done atomically: the database, an atomic primitive, a single owner.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Make Read-Modify-Write Atomic

NEVER read a shared value, modify it locally, and write it back as separate steps. Express the mutation as a single atomic operation at the layer that owns the data.

Read-modify-write across concurrent callers loses updates silently; the result is plausible numbers that are wrong.

- Counters and balances: wrong: `v = get(); set(v + 1)`. Right: `UPDATE t SET count = count + 1 WHERE ...`, Redis `INCR`, `AtomicInteger.incrementAndGet()`, `fetch_add`.
- Conditional mutation belongs in the same atom: `UPDATE inventory SET qty = qty - 1 WHERE id = ? AND qty > 0` and check rows-affected, instead of select-check-update.
- In-memory shared state: use atomics or take a lock around the *entire* read-modify-write, not around the read and the write separately.
- UI/state frameworks: use the functional form, `setCount(c => c + 1)`, never `setCount(count + 1)` from a possibly stale closure.
- Collections and JSON blobs count too: load-array, push, save-array is the same bug with a bigger payload. Use an append/array-push operation the store executes atomically, or version-check the write.
- If no atomic primitive exists at that layer, that's a design smell: move the mutation to a layer that has one (DB, single-writer task, actor) rather than hoping callers won't overlap.

**Red flags that you're about to violate this:**
- "Two requests won't realistically hit this at the same time."
- "It's just a view counter; close enough is fine."
- "I already have the value in a variable, might as well use it."
- "The whole handler is fast, the window is tiny."
- "I'll wrap it in a transaction" (a transaction without the right semantics still reads stale and overwrites).

---

## Why It Works

1. **It reframes `get → mutate → set` as three operations, not one,** which is the perceptual error that makes the bug invisible in review.
2. **It routes the AI to named atomic primitives** (`INCR`, `count = count + 1`, `fetch_add`, functional setState), so the correct alternative is a lookup, not an invention.
3. **It kills the "tiny window" rationalization with arithmetic:** the window is per-operation, the exposure is per-operation-times-traffic, and traffic is large.
4. **It scopes the lock correctly when a lock is the answer** — half the "fixed" versions of this bug lock the read and the write but not the gap between them.

## Origin

A promo-codes service tracked remaining redemptions with `remaining = row.remaining; save(remaining - 1)`. A marketing email landed in a million inboxes at 9:00 a.m., a few thousand people clicked within the same second, and a code limited to 500 uses was redeemed 1,940 times. The numbers in the table looked perfectly reasonable the whole time, which is the signature of a lost-update bug: nothing crashes, the math is just quietly fiction.
