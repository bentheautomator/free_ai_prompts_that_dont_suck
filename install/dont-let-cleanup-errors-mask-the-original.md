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
