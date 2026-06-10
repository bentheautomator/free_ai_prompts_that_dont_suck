### Add Jitter and Backoff to Every Retry

NEVER retry immediately or on a fixed interval. Every retry policy MUST use exponential backoff with randomized jitter and a retry budget. Failures are correlated — when a dependency breaks, all callers fail together, and unjittered retries form synchronized waves that keep the dependency down.

- Use exponential backoff with full jitter: `sleep(random(0, min(cap, base * 2^attempt)))`. The randomness is not optional garnish — it is the mechanism that decorrelates callers; exponential backoff alone still produces (spreading) waves.
- Cap total attempts (typically 2–4) and cap total elapsed time against the caller's deadline. Retrying past the point where anyone is still waiting for the answer is pure load, zero value.
- Retry only what can plausibly succeed on retry: timeouts, 5xx, connection resets, broker redelivery hints. Never retry 4xx (except 429), validation failures, or non-idempotent operations that may have partially succeeded — see your idempotency rules first.
- Honor `Retry-After` on 429/503 over your own schedule. The server is telling you its actual recovery plan.
- Count your layers: if the SDK retries 3x, your service retries 3x, and the client retries 3x, one failure costs 27 requests. Pick one layer to own retries (usually the lowest one with idempotency context) and make the others fail fast.
- For high-traffic paths, add a circuit breaker or retry-budget (e.g., retries may be at most 10% of requests) so a hard-down dependency gets near-zero traffic instead of maximum traffic.

**Red flags that you're about to violate this:**
- "I'll just retry after a one-second sleep."
- "Jitter is overkill for an internal service."
- "More retries means more reliability." (Means more load on whatever is already failing.)
- "Retry until it succeeds."
- "The SDK probably doesn't retry on its own." (Check. It does.)
- "It's fine, the dependency can handle a few extra requests." (Times every caller. In sync.)
