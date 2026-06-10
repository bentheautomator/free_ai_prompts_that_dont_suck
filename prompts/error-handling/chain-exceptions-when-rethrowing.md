---
title: Chain Exceptions When Rethrowing
slug: chain-exceptions-when-rethrowing
category: error-handling
tags: [universal, errors, exceptions]
works_with: all
severity: high
one_liner: "AI rethrowing wrapped errors that lose the original stack trace and cause"
---

# Chain Exceptions When Rethrowing

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents re-thrown errors from pointing at the catch block instead of the line that actually failed.

**[Copy-paste ready version](../../install/chain-exceptions-when-rethrowing.md)** — just the instruction block, no explanation.

## The Problem

`throw new Error(e.message)` looks like a faithful re-throw. It isn't. The new Error's stack trace starts at the `throw` statement — inside the catch block — and the original stack, the one that pointed at the actual failing line twelve frames down, is garbage-collected along with the original error object. Python's equivalent is `raise CustomError(str(e))` without `from e`; Java's is `throw new ServiceException(e.getMessage())` without passing `e` as the cause. In every case, the wrapper keeps the prose and discards the forensics.

AI assistants generate this constantly when asked to "wrap errors in a domain exception" or "add better error types," because the wrapping idiom they reach for takes a message argument, and `e.message` is the obvious message. The code compiles, the new exception type appears, the task looks complete. The damage is invisible until the next production incident, when every stack trace in the logs terminates at a catch block and the actual origin of the failure is unrecorded anywhere.

Re-throwing without chaining also erases the original *type* — a `TimeoutError` becomes a generic `Error`, so upstream retry logic that correctly retries timeouts no longer fires.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Chain Exceptions When Rethrowing

When you catch an error and throw a new one, ALWAYS attach the original as the cause. NEVER construct the replacement from `e.message` alone — that deletes the original stack trace and type.

- Python: `raise DomainError("context") from e` — never `raise DomainError(str(e))` bare. Inside an `except` block, even re-raising a new error without `from` implicitly chains, but be explicit: `from e` for wrapping, `from None` only when hiding the cause is a deliberate, commented decision
- JavaScript/TypeScript: `throw new DomainError("context", { cause: e })` — never `throw new Error(e.message)`
- Java/C#: pass the original as the constructor's cause/innerException argument: `throw new ServiceException("context", e)`
- Go: wrap with `%w` so `errors.Is`/`errors.As` still work: `fmt.Errorf("loading config: %w", err)` — `%v` or `err.Error()` breaks unwrapping
- The wrapper's own message should add context the original lacked (operation, identifiers) — duplicating `e.message` into the wrapper adds nothing and tempts you to skip chaining
- To re-throw unchanged, use the bare form that preserves the original: `raise` (Python), `throw;` (C#), re-`throw err` (JS) — not a reconstruction of it
- Ensure log formatters print the full cause chain (`exc_info=True`, logging `err.cause`); a chain nobody prints is a chain nobody sees

**Red flags that you're about to violate this:**
- "I'll wrap the message in our custom error class..."
- "new Error(e.message) keeps the important part..."
- "The message tells you everything the stack would..."
- "Converting to our error type means building a fresh one..."
- "The original error isn't needed once we've translated it..."

---

## Why It Works

1. **It targets the exact constructor call.** The failure is one specific keystroke pattern — error type, message argument, nothing else. Showing the correct constructor signature per language replaces the bad muscle memory with good muscle memory at the same level of effort.

2. **It separates "translate the type" from "discard the evidence."** The model conflates them: wrapping feels like it must create a fresh object. Cause parameters exist precisely so translation and preservation can coexist; naming them dissolves the false trade-off.

3. **It protects programmatic unwrapping, not just debugging.** `errors.Is`, `errors.As`, and instanceof-on-cause are behavior, not logging niceties — pointing this out raises the stakes from "less convenient" to "retry logic breaks."

4. **It closes the silent-chain gap with logging.** A preserved cause that no formatter prints is functionally lost; the formatter requirement makes the chain actually reach a human.

## Origin

A team had an assistant introduce a clean exception hierarchy across their service layer — every low-level error wrapped in a domain exception, built as `raise PaymentError(str(e))`. The refactor shipped quietly. Three weeks later a checkout failure hit production, and every log entry showed a `PaymentError` raised from the same wrapping line in the same module, for what turned out to be four different root causes. With no chained tracebacks, the team reproduced each failure manually in staging to find out what `str(e)` had been summarizing. Adding `from e` across the codebase was a 40-character-per-site fix that would have saved two engineer-days.
