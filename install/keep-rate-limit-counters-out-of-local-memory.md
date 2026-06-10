### Keep Rate-Limit Counters Out of Local Memory

NEVER enforce a rate limit, quota, or usage counter with process-local state in a service that can run more than one instance. Each replica counting privately means the effective limit is `limit × replicas`, it resets on every deploy, and it loosens exactly when you scale up under attack.

- Keep enforcement counters in a shared store with atomic operations: Redis `INCR` + `EXPIRE` (atomically, via pipeline or Lua), a token-bucket script, or your gateway's built-in distributed limiter. The check-and-increment must be one atomic step — read-modify-write from N replicas undercounts under concurrency.
- This covers every counter with consequences: per-user rate limits, plan quotas, failed-login lockouts, "max N concurrent jobs per account," coupon redemption caps, anything billed.
- Prefer enforcing at a layer built for it when available (API gateway, ingress rate limiting, CDN) and keep application-level limits for business quotas the edge can't see.
- Decide the limiter's failure mode explicitly: if the shared store is down, fail open (allow, log loudly) for revenue paths and fail closed for abuse/security paths (lockouts). Silence is the only wrong option.
- Local memory is acceptable only as a layered pre-filter (e.g., a per-instance cap to shed egregious floods before the Redis hop) — never as the authoritative count, and say so in a comment.
- Include the window design: fixed windows allow 2× bursts at boundaries; use sliding windows or token buckets when the limit actually matters.

**Red flags that you're about to violate this:**
- "A simple in-memory map keeps this dependency-free."
- "We only run one instance of this service." (Confirm the deployment, then ask about next quarter.)
- "Per-instance limiting is roughly the same thing."
- "Sticky sessions mean each user hits the same pod anyway." (Until a pod dies, scales, or deploys.)
- "It's just a soft limit, accuracy doesn't matter." (Then why is billing reading it?)
- "Redis adds latency to every request." (One INCR is sub-millisecond; quota fraud is not.)
