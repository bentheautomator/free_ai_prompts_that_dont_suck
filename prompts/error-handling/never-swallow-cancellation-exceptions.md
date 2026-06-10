---
title: Never Swallow Cancellation Exceptions
slug: never-swallow-cancellation-exceptions
category: error-handling
tags: [universal, errors, exceptions]
works_with: all
severity: high
one_liner: "AI catch-alls eating KeyboardInterrupt and CancelledError, breaking shutdown"
---

# Never Swallow Cancellation Exceptions

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents broad catches from eating the signals that mean "stop now" — Ctrl+C, task cancellation, shutdown.

**[Copy-paste ready version](../../install/never-swallow-cancellation-exceptions.md)** — just the instruction block, no explanation.

## The Problem

A worker loop gets the defensive treatment: `while True: try: process_next() except: continue`. Looks unkillable — and it is, literally. In Python, a bare `except:` catches `KeyboardInterrupt` and `SystemExit`; the operator's Ctrl+C becomes just another swallowed exception and the loop keeps spinning. The process can no longer be stopped politely. Kubernetes sends SIGTERM, the `sys.exit` it triggers gets eaten, and the pod has to be SIGKILLed — skipping every cleanup handler, dropping in-flight work on the floor.

Async code has the same trap with higher stakes. `except Exception:` in asyncio (Python 3.8+) doesn't catch `CancelledError`, but `except BaseException:` and bare `except:` do — and AI assistants emit all three interchangeably. A coroutine that swallows `CancelledError` breaks structured concurrency: `asyncio.wait_for` timeouts stop working, task groups hang on shutdown, and `await task` after `task.cancel()` never returns. In .NET, catching `Exception` without re-throwing `OperationCanceledException` quietly defeats every `CancellationToken` upstream.

The model writes these catches while thinking about business errors — bad data, network blips. Cancellation isn't an error in that sense at all; it's the runtime's control flow for "stop." Catching it is intercepting an instruction addressed to someone else.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Swallow Cancellation Exceptions

Cancellation and shutdown signals are control flow, not errors. NEVER let a catch block absorb them — they must always propagate.

- Python: never write a bare `except:`; use `except Exception:` at the broadest, which lets `KeyboardInterrupt` and `SystemExit` pass. Never use `except BaseException:` unless you re-raise unconditionally
- Python asyncio: if you must catch `asyncio.CancelledError` (to clean up), re-raise it after cleanup — a coroutine that swallows it breaks `cancel()`, `wait_for`, and task-group shutdown for every caller
- .NET: in a broad catch, let `OperationCanceledException`/`TaskCanceledException` escape — `catch (Exception ex) when (ex is not OperationCanceledException)` — or rethrow it first
- Java: catching `InterruptedException` requires either rethrowing it or restoring the flag with `Thread.currentThread().interrupt()` — never catch-and-continue, which erases the interrupt
- JavaScript: in broad `catch` blocks around abortable operations, check for `AbortError` (`e.name === 'AbortError'`) and re-throw it rather than treating it as a failure to retry or log as an error
- Worker loops that intentionally survive errors (`while True: try/except Exception`) must still die on cancellation — test that Ctrl+C and SIGTERM actually stop the process
- Never retry an operation that failed due to cancellation; the caller asked it to stop, not to try harder

**Red flags that you're about to violate this:**
- "A bare except makes this loop bulletproof..."
- "I'll catch BaseException to be thorough..."
- "CancelledError is an exception, so the error handler should handle it..."
- "Catch, log, continue — the worker must never die..."
- "I'll treat the abort like any other failed request and retry..."

---

## Why It Works

1. **It reclassifies cancellation out of the error category.** The model's handler logic applies to "errors," and cancellation exceptions are syntactically errors. Declaring them control flow — an instruction addressed to the runtime — removes them from the set the catch block is allowed to claim.

2. **Per-language specifics close per-language traps.** "Don't swallow cancellation" fails in practice because the swallowing looks different everywhere (bare except, `BaseException`, interrupt flags, AbortError). Concrete forms per ecosystem make the rule executable.

3. **It pairs the legitimate catch with a mandatory re-raise.** Cleanup-on-cancel is a real need; allowing catch-cleanup-reraise keeps that path open and makes the swallowing variant an obvious deviation.

4. **It adds an observable test.** "Does Ctrl+C still stop it?" is something the model (and reviewer) can actually verify, turning an invisible property into a checkable one.

## Origin

An assistant hardened a queue consumer with `try: ... except BaseException: log_and_continue()` so "no failure can kill the worker." None could — including SIGTERM during deploys. Every rollout thereafter hit the 30-second termination grace period and got SIGKILLed mid-message, producing a trickle of half-processed jobs that were re-delivered and double-executed. The team spent days investigating "duplicate processing under load" before anyone noticed deploys were the trigger and a one-word change (`BaseException` to `Exception`) was the fix.
