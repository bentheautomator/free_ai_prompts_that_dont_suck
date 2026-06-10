---
title: Preserve Error Handling When Restructuring
slug: preserve-error-handling-when-restructuring
category: refactoring
tags: [universal, refactoring]
works_with: all
severity: critical
one_liner: "Stops refactors from dropping try/catch blocks, retries, and cleanup paths"
---

# Preserve Error Handling When Restructuring

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from losing exception handlers, retry loops, timeouts, and cleanup logic when it reshapes the happy path.

**[Copy-paste ready version](../../install/preserve-error-handling-when-restructuring.md)** — just the instruction block, no explanation.

## The Problem

Error handling is the part of a function the model understands least and drops first. When an assistant restructures code, it rebuilds around the happy path, because the happy path is the function's "story" and the story is what the model retains. The `try/finally` that releases a lock, the `except ConnectionError` with backoff, the timeout on the HTTP call, the rollback in the failure branch: these wrap the story rather than advancing it, and wrappers fall off in transit. The refactored function does the same thing on success, which is the only case anyone checks, and something completely different on failure, which is the case that mattered.

Worse, extraction refactors mangle handling even when they keep it. Pull the body of a `try` block out into a helper and the question of *which* statements are still guarded gets re-decided implicitly. A catch that wrapped three calls now wraps one. A `finally` that ran after the loop now runs inside it. Failure semantics are positional, and refactors move positions.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Preserve Error Handling When Restructuring

When refactoring, the failure paths must survive exactly: every try/catch/finally, retry loop, timeout, fallback, rollback, and resource cleanup. NEVER restructure the happy path and rebuild error handling from approximation.

Error handling encodes the failures that actually happened. It is invisible in normal operation, which makes it the easiest behavior to lose and the costliest.

- Before restructuring, list the error-handling constructs in the target code: exception handlers and exactly which statements each guards, retry/backoff logic and its parameters, timeouts, `finally`/`defer`/context-manager cleanup, error logging, and fallback values.
- After restructuring, verify each item still exists, still guards the same operations, and triggers under the same conditions.
- Extraction changes guard scope silently. If a `try` wrapped statements A, B, and C, and B moves into a helper, decide explicitly where the handler lives now, and confirm A and C are still covered.
- Preserve handler specificity. Don't widen `except ConnectionError` to `except Exception` or narrow it; both change which failures take the recovery path.
- Preserve what handlers do: re-raise vs swallow, the exact fallback value, whether the original exception is chained, whether the error is logged before propagating.
- Cleanup ordering is behavior. A `finally` that closed the file before releasing the lock keeps doing both, in that order.
- If error handling looks excessive or wrong, keep it identical through the refactor and report your doubts separately. Failure paths are the worst possible place for silent opinions.

**Red flags that you're about to violate this:**

- "The new structure is cleaner without all the nested try blocks."
- "I'll consolidate these three catch blocks into one general handler."
- "This retry logic is overkill for a simple call."
- "The error handling can be simplified since these failures are rare."
- "I've kept equivalent error handling, just organized differently."

---

## Why It Works

1. **It explains why this code specifically gets lost.** "Invisible in normal operation" names the asymmetry: happy-path regressions surface immediately, failure-path regressions wait for an outage. Knowing the trap exists changes how the model treats wrapper code.
2. **The inventory makes guard scope an explicit decision.** Most damage here is positional (what's inside the `try` after extraction), and a per-handler before/after check is the only thing that catches a guard that silently shrank.
3. **"Equivalent error handling, organized differently" is pre-marked as a red flag.** That exact phrase is how models describe handling they rebuilt from vibes; flagging it forces verification instead of paraphrase.

## Origin

A queue-consumer refactor extracted message processing into a tidy helper. The original `try/except` had wrapped both processing and the acknowledgment call; after extraction, only processing was guarded. When a downstream dependency started timing out, exceptions from the ack path escaped the handler and killed the consumer process in a crash loop. The original author had wrapped both calls on purpose, after the previous crash loop.
