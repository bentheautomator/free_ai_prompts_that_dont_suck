### Rate-Limit Login, OTP, and Reset Endpoints

ALWAYS apply rate limiting and attempt caps when building authentication-adjacent endpoints, and NEVER remove or hollow out an existing limit to fix tests or load complaints.

An unthrottled login is a password oracle; an unthrottled 6-digit OTP check is a solvable puzzle, not a control.

- Endpoints that need limits by default: login, OTP/2FA verification, password reset request and reset-token submission, email verification, signup (abuse), API key validation, and anything comparing a short code. Build the limit with the endpoint, not as a hardening backlog item.
- Limit on two axes: per-target-account (stops distributed guessing against one user) and per-IP (stops one source spraying many accounts). IP-only misses botnets; account-only enables lockout-as-harassment — use both, with the account axis escalating to delays or step-up (CAPTCHA) rather than hard permanent lockout.
- Tiny keyspaces get hard caps: OTP and SMS codes allow 5-10 attempts, then invalidate the code and issue a new one. Reset tokens: long, random, single-use, expiring — and still capped.
- Use real infrastructure: the framework's limiter or a Redis-backed counter. An in-memory `Map` in one process limits nothing behind a load balancer; note this when you see it.
- When a limit blocks tests or load runs, the fix is test-shaped: dedicated test hooks, limiter exemptions for specific test credentials in non-prod config, or resetting counters between runs. Never raise the global threshold to "basically off," delete the middleware, or add an `X-Skip-RateLimit` style header check that ships to production.
- Respond to limited requests with 429 and no oracle: the response must not reveal whether the password would have been correct, or whether the account exists.

**Red flags that you're about to violate this:**
- "Rate limiting is an optimization, the auth logic is what matters for now..."
- "The E2E suite keeps tripping the limiter, I'll bump the max way up..."
- "Per-IP limiting covers it, attackers come from one place..."
- "Six digits plus a 10-minute expiry is too short a window to brute force..."
- "I'll add a bypass header so QA stops complaining..."
- "The in-memory limiter works in dev, distributed counters are over-engineering..."
