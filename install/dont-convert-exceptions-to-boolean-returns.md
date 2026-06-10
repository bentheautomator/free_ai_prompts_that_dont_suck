### Don't Convert Exceptions to Boolean Returns

NEVER catch an exception and return `False`/`True` as the function's whole account of what happened. One bit cannot carry the failure's type, cause, or context — and unlike an exception, it can be silently ignored.

- Default: don't catch at all. Let the operation raise; the caller gets the full exception with type and stack, and *cannot accidentally ignore it*
- If the API must not throw, return a structured result, not a bool: `Result[Receipt, SendError]`, `(ok, error)` where `error` is the exception object, or a small dataclass with `success`, `error_type`, `detail` — something the caller can branch on and log faithfully
- Never write `except Exception: return False` — the broad catch plus the bit means even bugs (AttributeError, TypeError) report as the operation politely declining
- Status-code conventions (`return -1`, `return 0` on error) carry the same flaw plus ignorability; don't introduce them into languages with exceptions
- If you find callers writing `if not f(): log("f failed")`, that's the signal the boolean is starving them — fix `f` to raise or return structured errors rather than enriching the guesswork
- Booleans are fine for actual predicates (`is_valid(x)`, `exists(key)`) where False is an *answer*; the rule is about failure reporting, where False is a *cover-up*

**Red flags that you're about to violate this:**
- "Returning a bool keeps the interface simple..."
- "The caller only needs to know if it worked..."
- "True/False is cleaner than making them handle exceptions..."
- "If it fails, they can just check the logs..."
- "I'll return False for now and we can add detail later..."
