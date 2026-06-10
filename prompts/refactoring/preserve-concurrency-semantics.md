---
title: Preserve Concurrency Semantics
slug: preserve-concurrency-semantics
category: refactoring
tags: [universal, refactoring, concurrency]
works_with: all
severity: critical
one_liner: "Stops refactors that change sync/async, parallelism, or locking behavior"
---

# Preserve Concurrency Semantics

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from altering execution concurrency during a refactor: sequential loops made parallel, locks dropped, sync code made async, or vice versa.

**[Copy-paste ready version](../../install/preserve-concurrency-semantics.md)** — just the instruction block, no explanation.

## The Problem

Concurrency is behavior, and refactors change it constantly while claiming to change shape. A sequential `for` loop over API calls becomes `Promise.all` because parallel is "obviously better." A lock gets dropped during restructuring because the critical section it guarded was split across two new functions and the model rebuilt only one of them inside it. A synchronous function turns `async` for consistency with its neighbors, and now every caller up the stack needs awaiting, or worse, doesn't get it and receives a promise where a value used to be.

Models treat concurrency mode as an implementation detail because syntactically it almost is: `await` here, `gather` there. But the sequential loop was sequential because the downstream API rate-limits at 10 requests per second. The lock ordering was deliberate because the reverse order deadlocks under load. These constraints live outside the code, in the behavior of dependencies and the history of incidents, exactly where a model can't see. Parallelizing a polite loop is how a refactor becomes a self-inflicted denial-of-service.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Preserve Concurrency Semantics

When refactoring, the concurrency behavior of the code is part of its behavior. NEVER change what runs sequentially vs in parallel, what is sync vs async, or what is protected by which lock, unless that change is the explicitly requested task.

Sequentiality, locks, and sync boundaries usually encode external constraints (rate limits, ordering requirements, deadlock history) that are invisible in the code itself.

- A sequential loop over I/O stays sequential. Do not introduce `Promise.all`, `asyncio.gather`, thread pools, or batch parallelism as an "improvement"; the loop may be the rate limiter. Propose parallelization separately if you think it's safe.
- Conversely, do not serialize existing parallelism; fan-out is often load-bearing for latency.
- Locks, mutexes, semaphores, and synchronized blocks survive restructuring with identical scope: the same statements guarded, acquired and released in the same order. When extraction splits a critical section, decide explicitly where the lock now lives and verify every formerly guarded statement still is.
- Do not convert sync functions to async or async to sync during cleanup. The color of a function is a contract with every caller; changing it ripples through the whole stack and changes scheduling behavior even when it compiles.
- Preserve what's awaited and when: moving an `await` earlier or later, or dropping a fire-and-forget, reorders observable work.
- Keep thread/task-local state, queue sizes, worker counts, and executor choices identical; they're tuning, not style.
- If the concurrency structure looks wasteful or wrong, finish the shape-preserving refactor and raise it as a separate observation.

**Red flags that you're about to violate this:**

- "These calls are independent, so I'll run them in parallel."
- "Making this async matches the rest of the codebase."
- "The lock can move inside the helper; it's the same thing."
- "Sequential awaits in a loop are a classic performance bug."
- "I'll modernize this to use the concurrent executor while restructuring."

---

## Why It Works

1. **It relocates the missing information.** The model parallelizes because the code shows no reason not to; stating that the reasons live *outside* the code (rate limits, deadlock history) explains why absence of visible justification isn't permission.
2. **It treats function color as a contract.** Sync/async conversions feel local to the model; naming the whole-stack ripple makes the true blast radius part of the decision.
3. **The lock-scope check targets the splitting failure.** Locks aren't usually deleted; they're orphaned when extraction divides their critical section. Requiring an explicit "where does the lock live now" decision catches the actual mechanism.
4. **The separate-proposal channel keeps real wins available.** Some loops genuinely should be parallelized; routing that through an explicit proposal preserves the optimization while removing the ambush.

## Origin

A cleanup of an order-import script converted its sequential per-record API loop to a parallel gather, "since the calls are independent." They were independent; the vendor's rate limiter didn't care. The import got the account temporarily blocked for abusive traffic, which also took down the production integrations sharing the same API key, during business hours, on inventory day.
