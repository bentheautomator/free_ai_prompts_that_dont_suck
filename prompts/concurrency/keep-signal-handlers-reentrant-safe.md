---
title: Keep Signal Handlers Reentrant-Safe
slug: keep-signal-handlers-reentrant-safe
category: concurrency
tags: [universal, concurrency, signals]
works_with: all
severity: high
one_liner: "Stops signal handlers from doing real work in a context that can't bear it"
---

# Keep Signal Handlers Reentrant-Safe

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from putting logging, allocation, locks, and cleanup logic directly inside signal handlers, where they interrupt arbitrary code and deadlock or corrupt state.

**[Copy-paste ready version](../../install/keep-signal-handlers-reentrant-safe.md)** — just the instruction block, no explanation.

## The Problem

Asked to "handle Ctrl+C gracefully," the AI writes a SIGINT handler that logs a shutdown message, flushes buffers, closes the database, and exits. The problem is *when* a signal handler runs: at any instruction boundary, including halfway through a `malloc`, mid-write inside the logging library, or while the main thread holds the very lock the handler is about to want. A handler that logs can re-enter a logger that's mid-log; a handler that allocates can re-enter an allocator whose internal state is torn; a handler that takes a lock held by the code it interrupted deadlocks the process with one thread. The resulting failures are once-a-month hangs at shutdown, reproducible by no one.

The AI does this because a signal handler looks like a normal callback, and callbacks are where work goes. Nothing in the syntax says "you are interrupting a non-reentrant function that will resume after you return." High-level runtimes soften this — CPython defers handlers to bytecode boundaries, Node turns signals into ordinary events — but soften is not eliminate: a Python handler that raises mid-`finally` or mutates shared state still corrupts in-progress logic, and any handler that does slow work blocks the second, angrier signal.

The portable, boring, correct pattern fits in one sentence: the handler sets a flag (or writes one byte to a pipe), and the main loop does the actual work.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Keep Signal Handlers Reentrant-Safe

A signal handler does ONE thing: record that the signal happened, then return. All real work — logging, cleanup, closing resources, exiting — happens in normal code that notices the record.

Handlers interrupt arbitrary code mid-operation; anything non-reentrant they touch (allocators, loggers, locks, most of your program) may be in a torn state.

- The pattern: handler sets a `sig_atomic_t`/atomic flag or writes one byte to a self-pipe / wakes an event (`asyncio`'s `add_signal_handler`, Go's `signal.Notify` channel are this pattern built-in). The main loop checks the flag and performs shutdown in a sane context.
- Inside the handler, never: allocate, log, print, take locks, call into your database/network clients, or call anything not explicitly async-signal-safe. In C that's a short documented list; in higher-level languages, behave as if the list were just as short.
- Never touch shared mutable program state from a handler beyond the single flag. The code you interrupted will resume and assumes its invariants held while it was gone.
- Don't raise exceptions from handlers into arbitrary interrupted code as your shutdown mechanism (Python's default KeyboardInterrupt mid-`finally` is the canonical mess); convert the signal to an event your loop consumes deliberately.
- Make second signals meaningful: first SIGINT requests graceful shutdown via the flag; a second one, or a timeout, force-exits. A graceful path that hangs must not be the only path.
- Register handlers early and once; re-registering or registering from threads invites platform-specific surprises.

**Red flags that you're about to violate this:**
- "It's just one log line to say we're shutting down."
- "Python/Node handles signals safely, so the handler can do anything."
- "The handler needs the lock to clean up the shared state properly."
- "Cleanup must happen *in* the handler or the process might die first."
- "It's worked every time I've Ctrl+C'd it."

---

## Why It Works

1. **Flag-and-return is enforceable by inspection:** a handler body longer than a few lines is visibly wrong, which makes review trivial in a domain where testing is nearly impossible.
2. **It transplants the work to a context with intact invariants** — the main loop holds no torn locks and no half-updated structures, so ordinary cleanup code becomes safe again rather than needing to be heroic.
3. **It frames reentrancy concretely** ("the interrupted code resumes and assumes its invariants held"), which is the mental model the callback-shaped syntax erases.
4. **The two-signal escalation rule prevents the classic overcorrection,** where graceful shutdown becomes a process you can't kill politely.

## Origin

A data-collection daemon's SIGTERM handler flushed its metrics buffer, which took the buffer's mutex — sometimes held by the main thread the signal had just interrupted mid-flush. Result: roughly one deploy in forty, the process ignored SIGTERM, waited out the orchestrator's grace period, and got SIGKILLed with its buffer unflushed, losing exactly the data the handler existed to save. Nobody could reproduce it locally. The fix was the textbook one: handler writes a byte to a pipe, main loop sees it, flushes with no signal anywhere in sight.
