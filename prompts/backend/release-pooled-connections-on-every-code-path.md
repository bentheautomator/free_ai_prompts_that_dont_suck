---
title: Release Pooled Connections on Every Code Path
slug: release-pooled-connections-on-every-code-path
category: backend
tags: [universal, backend, reliability]
works_with: all
severity: critical
one_liner: "Stops leaked connections from draining the pool and freezing the service"
---

# Release Pooled Connections on Every Code Path

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents connections checked out of a pool from leaking on error paths until the pool is empty and every request hangs waiting for one.

**[Copy-paste ready version](../../install/release-pooled-connections-on-every-code-path.md)** — just the instruction block, no explanation.

## The Problem

Pool leaks are the slowest-burning critical bug in backend code. The assistant writes `const client = await pool.connect()`, runs a query, and calls `client.release()` — on the last line of the function. Between checkout and release sit a query that can throw, a JSON parse that can throw, and an early `return` someone will add next sprint. Any of those paths exits the function with the connection still checked out. Forever. Pools don't reclaim what you don't return.

The failure profile is what makes it vicious. Nothing breaks at first: the pool has 20 connections and you're leaking one per rare error. Days later, the 20th leak empties the pool, and now every request — including perfectly healthy ones — blocks on `pool.connect()` until timeout. The service is "up" (health checks that don't touch the pool still pass), serving nothing, with CPU near zero. Restarting fixes it instantly, which is why teams restart nightly for months instead of finding the leak. The same shape applies to file handles, semaphore permits, distributed locks, and channel slots: acquire-without-guaranteed-release is the bug; the pool is just where it hurts most.

Assistants put release on the happy path because the happy path is the program they were asked for. Error-path resource hygiene is exactly the kind of invisible requirement that "it works" testing never exercises — errors in dev are rare, and twenty of them never happen before the next restart.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Release Pooled Connections on Every Code Path

Every acquired pooled resource MUST be released on every exit path — success, exception, early return, timeout, cancellation. Use the language's scope-guaranteed construct, never a release call at the end of the happy path.

- Use the guaranteed-cleanup idiom: `try/finally` or context managers (`with pool.connection()`) in Python, `try { ... } finally { client.release() }` in Node, `defer rows.Close()` / `defer conn.Release()` immediately after acquisition in Go, try-with-resources in Java. Acquisition and guaranteed release should be adjacent lines.
- Prefer APIs that scope the resource for you: `pool.query()` over manual `connect()`/`release()` when you don't need a transaction; helper functions like `withConnection(fn)` that own the acquire/release pair so callers can't get it wrong.
- In transactions, ensure rollback-then-release on the error path; releasing a connection with an open failed transaction back to the pool poisons the next borrower with "current transaction is aborted" errors.
- Set pool guardrails as defense in depth: acquisition timeout (so exhaustion produces loud fast errors, not silent hangs), max lifetime, and idle timeout. Log or alert on pool wait time and checked-out count — a leak is visible in those metrics weeks before the outage.
- Audit any early `return`, `continue`, or thrown exception between acquire and release — each one is a leak path unless the release is scope-guaranteed.
- The same rule covers file handles, locks, semaphores, and HTTP response bodies (unclosed bodies pin connections in keep-alive pools).

**Red flags that you're about to violate this:**
- "I release it at the end of the function."
- "The error case is rare, it won't matter."
- "The pool will clean up idle connections eventually." (Checked-out isn't idle. It waits forever.)
- "Adding try/finally everywhere is noisy."
- "GC will close it when the object is collected." (Maybe. Eventually. After the outage.)
- "We restart nightly anyway."

---

## Why It Works

1. **It moves correctness from discipline to structure.** A `finally`/`defer`/context-manager makes release a property of scope, not of every future editor remembering every exit path — including the early return someone adds next quarter.
2. **It prefers un-misusable APIs.** `withConnection(fn)` makes the leak inexpressible at call sites, which beats any rule that relies on call sites behaving.
3. **It covers the transaction-poisoning variant.** Releasing without rollback is the leak's subtler sibling: the pool stays full but hands out broken connections. Naming it prevents the "I added finally and it's still broken" round-trip.
4. **It makes the slow burn observable.** Pool-wait metrics and acquisition timeouts convert "mystery freeze after 11 days" into "alert: checked-out count climbing," which is debuggable on a weekday afternoon instead of at 3 a.m.

## Origin

An order-history endpoint released its connection after serializing the response — and a malformed legacy record made serialization throw for roughly one request in fifty thousand. Each throw kept one of twenty-five connections. About every nine days the pool emptied and the whole API froze with near-zero CPU; the team's runbook entry said, verbatim, "restart order-api, investigate someday." Someday arrived when the leak rate rose with traffic and the freezes went daily. The fix was moving one `release()` into a `finally`.
