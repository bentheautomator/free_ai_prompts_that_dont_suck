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
