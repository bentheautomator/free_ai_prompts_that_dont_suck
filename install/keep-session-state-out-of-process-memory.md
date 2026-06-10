### Keep Session State Out of Process Memory

NEVER store cross-request state — sessions, auth tokens, rate-limit counters, feature locks, shared caches — in process memory in a service that can run more than one instance. Assume every service will be horizontally scaled and restarted; in-process state silently diverges between replicas and evaporates on every deploy.

- Sessions and tokens go in a shared store (Redis, the database) or in signed tokens carried by the client. A `sessions = {}` dict at module scope is a bug, not a placeholder.
- Rate limiters and quotas count in a shared store with atomic operations. Per-process counters multiply every limit by the replica count.
- Anything mutated by one request and read by another (dedupe sets, "already sent" flags, in-flight job registries) must live somewhere all replicas can see.
- In-process caches are acceptable only for data that is immutable or harmlessly stale, and the cache must be a pure performance layer: the code must be correct with the cache removed.
- Do not "fix" this with sticky sessions unless explicitly asked. Stickiness hides the problem until a replica dies and takes its state with it.
- When local state is genuinely fine (per-request scratch data, config loaded at boot), keep it local. The rule is about state that outlives one request.

**Red flags that you're about to violate this:**
- "A simple in-memory map is fine for now; we can move it to Redis later."
- "This service probably only runs as a single instance."
- "The load balancer likely has sticky sessions enabled."
- "It's just a counter, it doesn't need to be exact."
- "Adding Redis for this one feature feels like over-engineering."
- "It works in staging, and staging mirrors production."
