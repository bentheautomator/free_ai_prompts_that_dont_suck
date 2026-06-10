---
title: Acquire Locks in One Global Order
slug: acquire-locks-in-one-global-order
category: concurrency
tags: [universal, concurrency, locks]
works_with: all
severity: critical
one_liner: "Prevents lock-ordering deadlocks that freeze production at 3 a.m."
---

# Acquire Locks in One Global Order

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from taking multiple locks in different orders on different code paths, which is the textbook recipe for a deadlock that only fires under real load.

**[Copy-paste ready version](../../install/acquire-locks-in-one-global-order.md)** — just the instruction block, no explanation.

## The Problem

Thread A locks `account_from` then `account_to`. Thread B, running the reverse transfer, locks `account_to` then `account_from`. Each holds one lock and waits forever for the other. Nothing crashes. Nothing logs. Two threads just stop, then every request that needs either lock queues up behind them, and twenty minutes later the whole service is wedged with healthy CPU graphs and zero throughput.

AI assistants produce this readily because each function is locally correct: "lock what you need, do the work, unlock" is exactly right in isolation. The deadlock isn't in any one function — it's in the relationship between two functions written in separate edits, possibly weeks apart. The AI never sees both call paths side by side, and neither does a test suite that runs operations one at a time. A deadlock needs two threads to arrive at the crossing simultaneously, which on a dev machine is roughly never and in production is roughly weekly.

The classic trigger is "transfer between two things of the same type": accounts, rooms, devices, documents. Lock both, in argument order, and you've shipped a coin-flip.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Acquire Locks in One Global Order

ALWAYS acquire multiple locks in a single, globally consistent order — everywhere, on every code path. Two code paths that take the same two locks in opposite orders will deadlock the first time they overlap; no test will catch it and no log will explain it.

- When locking two objects of the same type (two accounts, two rows, two files), sort by a stable key first: lock `min(a.id, b.id)` then `max(a.id, b.id)` — never in argument order.
- When locking objects of different types, define a fixed hierarchy (e.g., always user → account → ledger) and document it next to the lock definitions. Never lock "upward."
- Before adding a lock acquisition inside code that may already hold a lock, trace what's held at that point. Calling a function that locks B while holding A silently creates an A→B edge.
- Never call out to unknown code (callbacks, virtual methods, event handlers) while holding a lock — you can't know what it locks.
- If a consistent order is impossible, use try-lock with timeout and back off by releasing everything and retrying, and log loudly when it happens.
- Prefer designs needing one lock over designs needing two; a single coarser lock that's obviously correct beats two fine ones that deadlock.

**Red flags that you're about to violate this:**
- "These two locks are never held at the same time." (You checked every path?)
- "I'll lock them in the order the parameters came in."
- "This helper takes its own lock; the caller doesn't need to know."
- "Deadlock is unlikely; this code path is rare."
- "Sorting the lock order makes the code less readable."

---

## Why It Works

1. **It converts a global property into a local rule.** Deadlock-freedom requires reasoning over all paths at once, which neither the AI nor a reviewer does; "sort before locking" is checkable at the single line where locks are taken.
2. **It targets the same-type-pair trap explicitly,** which is where the symmetric-arguments deadlock almost always enters a codebase.
3. **It makes hidden lock edges visible** by forbidding lock acquisition inside opaque calls, where the A→B / B→A cycle usually hides.
4. **It defines what evidence counts:** "tests pass" exercises one interleaving out of millions, so absence of deadlock in CI proves nothing — only a provable acquisition order does.

## Origin

A payments service had a `transfer(from, to)` that locked accounts in parameter order. It ran fine for a year, because real users rarely sent money to each other simultaneously in both directions. Then a reconciliation batch job started issuing paired reversals, A→B and B→A in adjacent tasks. The service deadlocked nightly at the same minute, was "fixed" twice by restarts, and was finally diagnosed by a thread dump showing two threads each holding the lock the other wanted — a two-character fix (sort the IDs) after three weeks of blaming the database.
