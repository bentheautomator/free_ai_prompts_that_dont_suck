---
title: Drain In-Flight Work Before Shutdown
slug: drain-in-flight-work-before-shutdown
category: concurrency
tags: [universal, concurrency, shutdown]
works_with: all
severity: high
one_liner: "Stops shutdown paths that close resources while work is still using them"
---

# Drain In-Flight Work Before Shutdown

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from writing shutdown and cleanup code that closes pools, files, and connections while in-flight tasks are still using them.

**[Copy-paste ready version](../../install/drain-in-flight-work-before-shutdown.md)** — just the instruction block, no explanation.

## The Problem

The AI's shutdown handler is a list of `close()` calls: stop the server, close the DB pool, flush the logger, exit. It reads like a checklist and races like one. The HTTP server "stopped" but thirty requests are still mid-handler; they hit the closed pool and die with `connection closed` errors. The metrics buffer flushes, then two more tasks record metrics into a flusher that's gone. A worker is halfway through processing a message it has already received but will never ack. Every deploy now produces a small spray of 500s and a few half-processed jobs, and everyone learns to ignore the "deploy noise" in the error tracker — which is how real bugs hide in it later.

This happens because shutdown looks like a sequential procedure, and the AI writes it as one. The missing concept is that shutdown is a *negotiation with concurrent work*: stop intake, wait for in-flight work to finish, and only then tear down the resources it depends on. None of that is visible from the resources themselves; `pool.close()` doesn't know thirty handlers still hold its connections.

Tests never catch it because test shutdown happens at quiescence — there is no in-flight work to corrupt. Production shutdown happens mid-traffic, on every single deploy.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Drain In-Flight Work Before Shutdown

Shutdown order is ALWAYS: stop accepting new work → wait (with a deadline) for in-flight work to complete → then close the resources that work was using. Never close a resource before everything using it has finished.

A `close()` call doesn't wait for users of the resource; it strands them mid-operation.

- Stop intake first: stop listening / unsubscribe / pause the consumer. New work must stop arriving before anything else happens.
- Track in-flight work so you can wait for it: keep handles to spawned tasks (a `WaitGroup`, a task set, the server's built-in graceful-stop) — work you can't enumerate is work you can't drain.
- Wait with a deadline, then decide explicitly what happens to stragglers (cancel them, log them, nack their messages). An unbounded wait turns one stuck task into a hung deploy.
- Close in reverse dependency order: things that *use* go before things that are *used*. Handlers before the pool; the metrics-emitting tasks before the metrics flusher; consumers before the broker connection.
- Queue consumers: finish-or-nack every message already received. Stopping without settling received messages means redelivery at best, silent loss on auto-ack at worst.
- Wire this to the actual signals (SIGTERM, lifecycle hooks) and remember the platform's grace period is your total budget — drain deadline must fit inside it.

**Red flags that you're about to violate this:**
- "Shutdown is just closing everything in a row."
- "The process is exiting anyway, who cares about in-flight requests."
- "Close is probably graceful by default." (Check. It usually isn't.)
- "Deploy-time errors are expected noise."
- "I'll flush the buffer at the start of shutdown" (while things are still writing to it).

---

## Why It Works

1. **It imposes the three-phase shape** (stop intake → drain → teardown), turning shutdown from a list of closes into a protocol the AI can't reorder without noticing.
2. **"Track what you spawn" is the enabling mechanism** — draining is impossible without handles, and the rule makes untracked tasks a violation before shutdown is even involved.
3. **Reverse dependency order is checkable in review:** for each `close()`, ask "who still uses this?" — a concrete question with a findable answer.
4. **The deadline requirement prevents the overcorrection** where graceful shutdown becomes a deploy that never finishes because one task is wedged.

## Origin

A payments worker handled SIGTERM by closing its database pool, then its queue connection. Messages mid-handler failed their final write, but the queue library auto-acked on receipt, so the half-processed payments were never redelivered. Every deploy lost zero to three payment confirmations, attributed for months to "flaky webhook deliveries." The fix reordered four lines and added a fifteen-second drain; the incident review's most-quoted line was "the bug was deployed forty times a week, on purpose, by us."
