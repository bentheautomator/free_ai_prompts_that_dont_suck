### Never Retry Client Errors

Retry ONLY errors that can plausibly succeed on a second attempt without anything changing. NEVER retry an error caused by the request itself.

Retrying a deterministic failure doesn't add resilience — it multiplies load, delays the real error, and disguises a bug as flakiness.

- Retryable: network timeouts, connection resets, HTTP 502/503/504, and 429 (only while honoring the `Retry-After` header if present)
- Not retryable: HTTP 400, 401, 403, 404, 405, 409, 422 — validation failures, bad credentials, missing resources, and conflicts will fail identically every attempt; fail immediately and surface the response body
- The same taxonomy applies outside HTTP: retry a database deadlock or connection drop; never retry a constraint violation, a syntax error, or a serialization failure of your own payload
- Write the retry condition as an explicit allowlist of retryable statuses/exception types, not `except Exception` around the whole call
- A 401/403 must propagate loudly — it usually means an expired or misconfigured credential, and every retry delays that discovery
- If a library's built-in retry is in use (urllib3 `Retry`, axios-retry), configure its `status_forcelist`/condition explicitly; defaults are not a decision

**Red flags that you're about to violate this:**
- "I'll retry on any exception to make it resilient..."
- "Five attempts with backoff should handle most failures..."
- "A 400 might be transient on their end..."
- "Retrying auth errors covers token race conditions..."
- "It's simpler to retry everything than to classify errors..."
