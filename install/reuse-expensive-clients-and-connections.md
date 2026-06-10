### Reuse Expensive Clients and Connections

NEVER construct a connection-holding or handshake-performing object (database connection, HTTP client/session, gRPC channel, cloud SDK client, message-broker producer, search client) inside per-request or per-item code. These objects are designed to be created once and shared; they carry pools, keep-alive sockets, and token caches that only pay off across calls.

- Create clients at module scope, app startup, or via dependency injection with singleton lifetime; handlers and loop bodies receive the existing instance.
- Databases get a connection *pool* created once; per-request code borrows and returns. Constructing connections per request is both a latency tax (handshake per call) and an outage vector (max_connections exhaustion under load).
- Bare `requests.get()`/`fetch` calls in loops forfeit keep-alive: each call may re-handshake TCP+TLS. Use a `requests.Session`, `httpx.Client`, or the platform's pooled agent held across calls.
- Most official SDK clients (AWS, GCP, Stripe-style) are thread-safe and intended as singletons; check the docs and share one instance. Per-call construction can also re-trigger credential resolution against metadata endpoints, adding network calls you never see.
- If a client must be per-request (request-scoped auth), keep the *transport* shared (pooled connections under per-request credentials) where the library supports it.
- Verify at the connection layer: under a burst of requests, connection counts (`pg_stat_activity`, `netstat`/`ss` counting TIME_WAIT, client pool metrics) should be stable and small, not proportional to request count.

**Red flags that you're about to violate this:**
- "Creating the client in the function keeps it self-contained."
- "The SDK quickstart instantiates it right before the call."
- "Connections are cheap."
- "I don't want to deal with shared state or thread safety."
- "We close it right after, so nothing leaks."
- "It's one extra object per request, the GC handles it."
