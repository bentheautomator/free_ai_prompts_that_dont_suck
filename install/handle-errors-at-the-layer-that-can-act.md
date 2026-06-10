### Handle Errors at the Layer That Can Act

Catch an error at the layer that has both the context to decide what it means and the power to do something about it. Low-level helpers should add context and propagate — NEVER absorb errors and return degraded values on behalf of callers they know nothing about.

- A reusable function (HTTP helper, DB accessor, file util) must not decide that its own failures are tolerable; it doesn't know whether the caller is rendering a widget or moving money
- Default behavior for low layers: let the exception propagate, optionally wrapping it with added context (`raise StorageError(f"writing {path}") from e`) — do not catch-log-return-None
- Catch at the layer where a meaningful decision exists: the request handler that can return a 503, the job runner that can reschedule, the orchestration code that knows whether this step is optional
- One error, one handling site: if the bottom layer already logged-and-absorbed, the top layer can never apply its policy; if both handle, you get duplicate handling and contradictory outcomes
- "Adding error handling" to a utility usually means *removing* the decision from it: wrap-and-rethrow with context is the utility's whole job
- If a helper must offer a lenient mode, make it explicit at the call site (`fetch(url, on_error="return_none")`) so each caller opts in knowingly rather than inheriting a hidden policy

**Red flags that you're about to violate this:**
- "I'll handle the error right where the request is made..."
- "The helper can just log it and return None..."
- "Callers shouldn't have to worry about failures..."
- "This keeps the exception from bubbling up..."
- "Every function should handle its own errors..."
