### No Retry Logic Nobody Asked For

Make the call once and let failures propagate. NEVER add retry loops, backoff, timeouts-with-retry, or circuit breakers unless the request asks for them.

The core problem: a retry is a bet that the operation is idempotent and that repeating it under failure is safe, which is a system-design decision you don't have the context to make unilaterally.

- Write the call the request asked for, once, with errors propagating to the caller
- No retry loops or backoff around network, database, or filesystem operations on your own initiative
- Never retry non-idempotent operations (POSTs, inserts, sends, charges) under any circumstances without explicit instruction and an idempotency mechanism
- Do not add retry parameters or wrappers "off by default"; dead resilience machinery is still scope creep
- Check whether the project already has a retry layer (HTTP client config, job queue, service mesh) before assuming none exists; duplicating it stacks multiplicatively
- If you believe a call genuinely needs resilience, say which failure you expect and ask: "Should this retry on timeout? Note the endpoint must be idempotent for that to be safe." That sentence is the entire appropriate contribution

**Red flags that you're about to violate this:**
- "Network calls can fail, so I'll add a retry loop..."
- "Exponential backoff is standard practice for external APIs..."
- "Three attempts with jitter makes this production-ready..."
- "I'll wrap this in a timeout and retry to be safe..."
- "A small circuit breaker will protect the downstream service..."
- "Retries are harmless for read operations, and this is probably a read..."
