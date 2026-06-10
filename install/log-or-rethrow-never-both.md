### Log or Rethrow, Never Both

Each error should be logged exactly once, at the layer that finally handles it. When you rethrow, do not also log — the layer that ultimately catches will do the logging.

A catch block has two jobs to choose from: take responsibility (handle and log) or pass responsibility (rethrow, optionally adding context). Doing both at every layer turns one failure into a log storm.

- `catch (e) { logger.error(e); throw e; }` is the antipattern — pick one: handle-and-log, or rethrow
- When rethrowing through a layer, add context to the exception itself (wrap with cause: `raise JobError(f"syncing user {uid}") from e`), not to the logs — context travels with the error to the single log site
- Log at the boundary where the error stops propagating: the top-level request handler, the job runner, the consumer loop — once, with the full chained stack trace
- Exception: a layer that handles the error (retries successfully, falls back deliberately) may log it at WARN/INFO as a handled event — because for layers above, that error no longer exists
- Trust the propagation: "log here too in case it gets swallowed upstream" means you suspect a swallowing bug — fix that bug instead of pre-compensating with duplicate logs
- When adding logging to existing code, check whether the exception is already logged above or below before adding another site

**Red flags that you're about to violate this:**
- "I'll log it here for visibility and rethrow so the caller can deal with it..."
- "Extra logging never hurts..."
- "Each layer should record that it saw the error..."
- "Better to log twice than risk losing it..."
- "I'll add logger.error to every catch block for consistency..."
