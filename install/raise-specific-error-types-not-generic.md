### Raise Specific Error Types, Not Generic

When raising an error, raise a type a caller could catch selectively. NEVER raise the base class — `Exception`, `Error`, `RuntimeError` with prose — for a failure that has a name.

The type is the API of the failure. Prose is for humans; the class is what code branches on.

- First, reuse: check whether the project defines domain exceptions (`NotFoundError`, `ValidationError`) or whether a built-in fits exactly (`ValueError` for bad arguments, `KeyError`, `TimeoutError`, `FileNotFoundError`) — raise the most specific existing fit
- If a distinct failure has no type, define one — a one-line class (`class QuotaExceededError(Exception): pass`) is cheap, and inheriting from the project's base exception keeps it catchable in bulk too
- Distinct failures that callers will treat differently need distinct types: not-found, permission-denied, and quota-exceeded raised as one shared class with different messages forces callers back to string matching
- In JavaScript/TypeScript, subclass `Error` (`class RateLimitError extends Error`) or set a stable `code` property; never throw plain strings or object literals, which lack stacks and instanceof identity
- Give structured fields to the type, not just the message: `QuotaExceededError(limit=100, retry_after=30)` lets handlers act on the numbers without parsing prose
- Don't go taxonomically wild either: a new exception class per call site is noise — one type per *distinct caller-visible failure*, organized under a small module hierarchy

**Red flags that you're about to violate this:**
- "raise Exception with a clear message is enough..."
- "Defining a custom exception class is overkill here..."
- "The message tells the caller exactly what went wrong..."
- "I'll use RuntimeError; it's basically for things like this..."
- "Callers can check the text if they need to distinguish..."
