---
title: Don't Let Cleanup Errors Mask the Original
slug: dont-let-cleanup-errors-mask-the-original
category: error-handling
tags: [universal, errors, exceptions]
works_with: all
severity: medium
one_liner: "AI finally blocks that throw, replacing the real error with a cleanup error"
---

# Don't Let Cleanup Errors Mask the Original

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents a throwing finally block from overwriting the exception you actually needed to see.

**[Copy-paste ready version](../../install/dont-let-cleanup-errors-mask-the-original.md)** — just the instruction block, no explanation.

## The Problem

A function throws halfway through, and on the way out its `finally` block runs cleanup: `finally: conn.close()`. But the connection is in a broken state *because* of the original error, so `close()` throws too — and in most languages, the exception that escapes the function is the cleanup one. The caller sees "error closing connection." The actual failure, the one that explains everything, is gone (Java without suppression, JS) or buried as a `__context__` nobody prints (Python). Debugging now starts from the wrong error.

There's a mirror-image failure: AI assistants also write `finally` (and `defer`, and `__exit__`) blocks containing `return` statements or broad try/catches, which *swallow* the in-flight exception entirely — `finally: return result` in Python and JavaScript discards any propagating error, silently. One overwrite, one erase; both come from the same blind spot: cleanup code is generated as if it runs in a vacuum, when in fact it often runs *because* something just exploded, in a world where resources are already in a bad state.

The pattern multiplies in rollback handlers — `except: tx.rollback(); raise` looks right until rollback itself throws on a dead connection and replaces the original exception.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Don't Let Cleanup Errors Mask the Original

Cleanup code (finally, defer, catch-side rollback, context-manager exits) runs when an exception may already be in flight. It must neither replace that exception nor erase it.

- Never put a `return`, `break`, or `continue` inside a `finally` block — in Python and JavaScript these silently discard the propagating exception
- Cleanup that can itself fail (closing broken connections, rolling back on a dead transaction, deleting temp files) must be wrapped so its failure is logged at WARN but does not propagate: `finally: try: conn.close() except Exception: logger.warning("close failed during error handling", exc_info=True)`
- The original exception always wins: if both the operation and its cleanup fail, the operation's error is the one that must escape; attach the cleanup error as suppressed/secondary if the language supports it (Java `addSuppressed`, Python sets `__context__` automatically — make sure logs print it)
- In rollback handlers, guard the rollback: `except Exception: try: tx.rollback() except Exception: log; raise` — re-raise the *original* error outside the inner try
- Prefer constructs that handle this correctly for you: Python context managers / `contextlib.ExitStack`, Java try-with-resources, Go `defer` with explicit error capture — over hand-written finally chains
- Cleanup must be written for the failure case: assume the resource may already be broken, half-open, or gone when cleanup runs

**Red flags that you're about to violate this:**
- "The finally block just closes things, it can't fail..."
- "I'll return the result from finally so it always returns..."
- "rollback() is safe to call anywhere..."
- "If cleanup throws, that's the error we should see anyway..."
- "I don't need a nested try inside an except block..."

---

## Why It Works

1. **It corrects the model's mental execution context for cleanup.** Generated finally blocks assume a healthy world; stating that cleanup often runs *because* the world just broke explains why `close()` and `rollback()` are likely to throw exactly when it matters.

2. **It establishes a precedence rule.** "The original exception always wins" resolves the two-errors-at-once situation that languages handle inconsistently, giving the model one answer to encode regardless of ecosystem.

3. **It bans the silent-discard syntax outright.** `return` in finally is a one-token bug with no legitimate use in this context; a flat prohibition is cheaper than judgment.

4. **It points at the constructs that already solve this.** try-with-resources, context managers, and ExitStack encode suppression semantics correctly; steering generation toward them replaces a subtle hand-rolled pattern with a battle-tested one.

## Origin

A data pipeline began failing nightly with "SSLSocket closed" raised from a connection-cleanup helper. Three separate fixes targeted connection pooling over two weeks; the error persisted. The actual failure was a query timeout — visible nowhere, because the AI-written `finally: conn.close()` threw on the timeout-poisoned socket and replaced the timeout exception every single night. Once cleanup was wrapped and the original error surfaced, the real fix (one query hint) took an afternoon.
