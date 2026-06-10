---
title: Don't Share One Connection Across Tasks
slug: dont-share-one-connection-across-tasks
category: concurrency
tags: [universal, concurrency, resources]
works_with: all
severity: critical
one_liner: "Stops concurrent tasks from interleaving on a single non-thread-safe connection"
---

# Don't Share One Connection Across Tasks

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from handing one connection, session, or client object to many concurrent tasks when the object was never designed for concurrent use.

**[Copy-paste ready version](../../install/dont-share-one-connection-across-tasks.md)** — just the instruction block, no explanation.

## The Problem

The AI creates one database connection at startup and lets every request handler use it — or grabs a single connection from the pool, then fans out five concurrent queries on it with `gather`. Most connection objects are stateful protocol machines: one transaction state, one result cursor, one byte stream. Two tasks issuing commands concurrently interleave at the protocol level, and the failure menu runs from loud (`commands out of sync`, `cannot perform operation: another operation is in progress`) to quiet and horrifying: task A reads the result set belonging to task B's query, or a `ROLLBACK` issued by one task aborts a transaction another task believed it owned.

This is a default behavior because sharing one client *looks* like good resource hygiene — why open many when one works? — and because the object's thread-safety contract lives in documentation the AI isn't reading. Plenty of clients are safe to share (most HTTP clients, Redis clients with internal pipelining, pool *handles*); plenty aren't (raw DB connections, ORM sessions, SMTP/FTP/serial connections, most websocket client objects, cursors). The shapes are identical at the call site. And it all works perfectly in tests, where requests arrive one at a time and the protocol never interleaves.

The pool exists precisely to solve this. The bug is bypassing it — caching a checked-out connection in a long-lived variable is the same mistake with extra steps.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Don't Share One Connection Across Tasks

NEVER let multiple concurrent tasks use a single connection, session, or cursor unless its documentation explicitly guarantees concurrent use. Default assumption: stateful clients are single-task objects.

A connection is a protocol state machine; two concurrent users interleave commands and read each other's results.

- Share the *pool*, not a connection: acquire per task/request, release when done. Wrong: `conn = pool.acquire()` at module scope. Right: acquire inside the handler, in a `with`/`try-finally` that guarantees release.
- Never fan out on one connection: `gather(q1(conn), q2(conn), q3(conn))` interleaves three queries on one wire. Either run them sequentially on that connection or acquire one connection per concurrent query.
- ORM sessions (SQLAlchemy `Session`, EF `DbContext`, Hibernate `Session`) are single-task objects, full stop. One per request/task; never a module-level or singleton session.
- Check the contract before sharing anything stateful: HTTP clients are usually designed for concurrent use; DB connections, cursors, SMTP/IMAP/FTP clients, and serial ports usually are not. "It has async methods" is not the same claim as "it supports concurrent calls."
- Transactions bind to connections: everything in one transaction must run on the one connection that opened it, and *only* that work runs there until commit/rollback.
- If a connection must be shared (a single websocket, a serial line), serialize access through one owner task and a queue — others submit messages, never touch the socket.

**Red flags that you're about to violate this:**
- "One connection for the whole app is more efficient than a pool."
- "The client has async methods, so concurrent calls must be fine."
- "I'll cache the acquired connection so I don't pay acquisition cost per request."
- "These three queries are read-only, they can't conflict." (They share one result stream.)
- "It's worked fine so far." (Requests haven't overlapped yet.)

---

## Why It Works

1. **"Share the pool, not the connection" is a drop-in correction** for the exact resource-hygiene instinct that causes the bug — the AI keeps its efficiency goal and loses the protocol corruption.
2. **It sets the default to unsafe-until-documented,** which matches reality: concurrency support is a specific documented guarantee, not a property inferred from method signatures.
3. **The owner-task-plus-queue pattern handles the genuinely-singular cases** (one websocket, one serial port) so the rule doesn't collapse when sharing is unavoidable — serialization moves into structure instead of hope.
4. **Tying transactions to connections preempts the subtlest variant,** where queries "work" but commit and rollback land on the wrong task's transaction state.

## Origin

A reporting service held one Postgres connection in a module global "to keep things simple." Under concurrent dashboard loads, two handlers interleaved on it; one intermittently received the other's result rows, and a revenue widget briefly displayed another tenant's numbers. The error logs were empty — the protocol didn't break, the *answers* did. It reproduced only under parallel load and vanished under scrutiny, until someone noticed both stack traces shared one connection ID. Per-request acquisition from the pool fixed it the same afternoon.
