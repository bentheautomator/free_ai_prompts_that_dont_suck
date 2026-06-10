### Put Cross-Cutting Concerns at Seams

NEVER implement a cross-cutting concern — logging, auth checks, retries, timing, rate limiting, tracing, input sanitization, transaction wrapping — inline in individual functions. These belong at the codebase's seams: middleware, decorators, interceptors, base classes, or wrapper utilities that apply uniformly.

Inline copies are almost-uniform by construction: the gaps and drift between copies are exactly where the security holes and unsearchable logs live.

- First, find the seam the codebase already has: a middleware stack, a `@requires_auth`-style decorator, an interceptor chain, a `with_retries()` helper. Use it. Most codebases have one; the failure is not looking
- If the seam exists but lacks your case (a new permission level, a new retry policy), extend the seam — one change, every route — instead of going inline in your handler
- If no seam exists and you need the concern in 3+ places, build the smallest one (a decorator or wrapper function is enough) and apply it; don't lay copy number one of a future fifty
- Never hand-roll an inline retry loop, manual timing pair, or ad-hoc permission check next to an established mechanism that does the same thing
- Concern logic that genuinely varies per function (a domain-specific audit message) can be inline — but the transport of it (how it's logged, where it goes) still flows through the seam

**Red flags that you're about to violate this:**
- "I'll just add the check at the top of this one function..."
- "Touching the middleware affects every route, that feels too risky..."
- "The other handlers all have this block inline, so I'll match them..."
- "A retry loop is six lines, a shared helper is overkill..."
- "This endpoint is special, it can do its own logging..."
