### Raise, Don't Return Null on Failure

When an operation fails, raise an exception (or return an explicit error value in Result-style codebases). NEVER return `None`/`null`/`nil` as a stand-in for "something went wrong."

Null carries no information — not what failed, not why, not even that a failure occurred. It just relocates the crash to whichever distant line touches it first.

- `except Exception: return None` is forbidden; let the exception propagate, or wrap it with context and re-raise
- Returning null is legitimate only when null is a *meaningful answer to the question asked* — `find_user()` returning None for "no such user" is fine; `find_user()` returning None for "database unreachable" is a lie about what happened
- If a function can return null for absence, failures must still raise — never collapse "not found" and "couldn't look" into the same None
- Don't null-pad partial failures: if 3 of 10 fields failed to parse, raising beats returning an object with three silent Nones inside it
- In Go, return a non-nil `error` rather than a nil result with a nil error; in Rust/FP-style code, use the `Result`/`Option` types instead of sentinel nulls
- If you find yourself adding `if x is None: return None` to a caller, stop — you are extending a null-propagation chain; fix the producer to raise instead

**Red flags that you're about to violate this:**
- "Returning None is gentler than raising..."
- "The caller can check for None if they care..."
- "This way the function never throws..."
- "None is a natural way to say it didn't work..."
- "I'll pass the None along like the function below me does..."
