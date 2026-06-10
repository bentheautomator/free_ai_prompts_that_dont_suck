### Don't Let Error Handlers Throw

Code inside a catch/except block must be written defensively — it runs at the worst possible moment, against the least predictable inputs, and if it throws, it destroys the very error it was supposed to report.

- Never chain optional fields optimistically in a handler: `e.response.status_code` crashes when `response` is None (true for timeouts/connection errors in most HTTP libraries); write `status = e.response.status_code if e.response is not None else "no response"`
- Don't assume error payloads parse: `e.response.json()["message"]` assumes a body, valid JSON, and a `message` key — three assumptions about a *failure*; fall back to raw text, truncated: `body = e.response.text[:500] if e.response else ""`
- In JavaScript, `catch (e)` receives anything — not necessarily an Error: check before using (`e instanceof Error ? e.stack : String(e)`); accessing `e.response.data.message` off an unknown deserves optional chaining and a fallback
- Keep handlers short and dumb: log the exception object itself with the language's built-in formatting (`logger.error("request failed", exc_info=True)`, `logger.error(err)`) rather than hand-assembling messages from its internals — the built-in path doesn't crash on missing fields
- Anything nontrivial a handler does (cleanup calls, notification sends, metrics) can itself fail; if the handler must do real work, guard that work so the original exception still gets reported and re-raised first or regardless
- Test the handler with the *poorest* error available (timeout with no response, non-JSON body), not just the rich one

**Red flags that you're about to violate this:**
- "The error will have a response object with the details..."
- "I'll pull message out of the error body for a nicer log line..."
- "Status code is always there on a failed request..."
- "The catch just formats and logs; nothing to go wrong..."
- "The SDK's exceptions all have a .code attribute..."
