### Preserve Exception Types and Error Codes

When refactoring, a function's failure interface is frozen: the same conditions must produce the same exception types, error codes, status codes, and failure styles as before. NEVER change what code throws or returns on failure while changing its shape.

Every throw has catchers you can't see: upstream handlers, global error mappers, client retry logic, monitoring matchers.

- Keep exception types exact. Don't replace `ValueError` with a custom exception, a subclass, or a wrapper; don't consolidate distinct exception types into one "cleaner" hierarchy mid-refactor. `except` clauses upstream match on these names.
- Keep failure style: a function that throws keeps throwing; one that returns `None`/error tuples/Result objects keeps doing that. Converting between styles changes every caller's correctness silently.
- Keep error codes, enum values, and HTTP statuses byte-identical: `INSUFFICIENT_FUNDS` stays `INSUFFICIENT_FUNDS`; the 422 stays 422. Clients branch on these.
- Preserve which condition maps to which error. If empty input raised `ValidationError` and malformed input raised `ParseError`, don't merge them; callers may handle them differently.
- When wrapping or re-raising, preserve the original chaining behavior (`raise ... from e`, `cause`); error-reporting tools and debugging depend on it.
- Exception message text is lower-stakes but not free: anything matching on messages (tests, log alerts, client code that shouldn't but does) breaks. Don't reword messages without a reason, and mention it when you do.
- If the error design is genuinely bad, propose a redesigned failure interface as separate work with a deprecation story; never install it during cleanup.

**Red flags that you're about to violate this:**

- "I'll introduce a proper exception hierarchy while I'm in here."
- "Returning None is cleaner than throwing for a missing record."
- "These three error types are redundant; one will do."
- "400 is the more appropriate status for this case."
- "I'm just making the error handling consistent with the rest of the module."
