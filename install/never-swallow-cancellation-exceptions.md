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
