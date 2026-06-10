### Don't Collapse Distinct Errors Into One Response

Failures that mean different things to the caller MUST produce distinguishable outcomes. NEVER funnel validation errors, not-found, permission failures, and downstream outages into one generic catch-all response.

- In request handlers, map error categories before the catch-all: `except ValidationError: 400 with field details`, `except NotFound: 404`, `except PermissionDenied: 403`, `except UpstreamTimeout: 503 (retryable)` — then `except Exception: 500` for the truly unexpected
- The catch-all is for bugs only; if a known failure type is reaching it, that's a missing clause, not acceptable coverage
- Distinguishable means machine-distinguishable: different status codes / error codes (`{"error": {"code": "INVALID_EMAIL"}}`), not different prose in the same 500
- Never return 500 for a client mistake — the caller can fix a 400; a 500 tells them to wait and retry, which is exactly wrong for bad input
- Same rule beyond HTTP: CLIs should use distinct exit codes or distinct stderr messages per failure class; RPC handlers should use the protocol's status taxonomy (e.g. gRPC `INVALID_ARGUMENT` vs `UNAVAILABLE`), not `UNKNOWN` for everything
- Expected domain failures may carry detail to the caller; the generic 500 path should log full detail server-side but expose no internals (no stack traces or query text in responses)

**Red flags that you're about to violate this:**
- "One except clause at the bottom covers every case..."
- "It's all errors to the client anyway..."
- "Returning 500 for everything is simpler and safer..."
- "The client can read the message if they need specifics..."
- "I'll add granular handling later; generic works for now..."
