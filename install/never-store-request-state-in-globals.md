### Never Store Request State in Globals

NEVER store request-scoped data — current user, tenant, locale, auth token, trace ID, the request object itself — in a global, module-level, static, or singleton-instance variable. The process is shared by all concurrent requests; anything stored process-wide will be read by the wrong request under load, which means one user seeing another user's data.

- Pass request state explicitly through function parameters, or carry it in the mechanism built for this: `contextvars` (Python async), `AsyncLocalStorage` (Node), `context.Context` (Go), request-scoped DI beans (Java/Spring), `flask.g`/`request` (which are context-local, not true globals).
- Never use thread-locals in async runtimes: one thread interleaves many requests, so thread-local is just a slower global.
- Keep fields like `currentUser`, `requestId`, or `tenantId` off singleton services. Singletons may hold configuration and connections (immutable or internally synchronized) — never per-request values.
- In Python, never use mutable default arguments (`def f(items=[])`) or module-level mutable containers as scratch space; they persist across requests for the life of the worker.
- Treat caches keyed without a tenant/user component as the same bug: a "current permissions" cache with a global key serves the first caller's permissions to everyone.
- If a global must be mutated at request time, stop — that is the design error, not an implementation detail to synchronize.

**Red flags that you're about to violate this:**
- "I'll store the user in a module variable so I don't have to pass it everywhere."
- "Setting it in middleware and reading it later is cleaner."
- "Each request gets its own thread, so a static field is fine." (Not in async. Not with pooled threads.)
- "It's just a temporary scratch variable."
- "This service is a singleton, so I'll put the request on it."
- "We've never seen wrong data in dev or staging." (One user at a time never collides.)
