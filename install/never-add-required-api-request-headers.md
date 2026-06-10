### Never Add Required API Request Headers

NEVER make a request header mandatory on an existing endpoint — neither a new header nor stricter enforcement of an existing one. A header introduced today is, by definition, sent by zero existing callers; requiring it rejects the entire installed base in one deploy, and middleware-level enforcement does it across every endpoint simultaneously.

- New headers (`X-Request-ID`, `X-Client-Version`, `X-Tenant-ID`, `Idempotency-Key`, custom auth-adjacent metadata) must be optional with a server-side default: generate the request ID, infer the tenant from the existing auth context, treat absent idempotency keys as non-idempotent requests — exactly as the endpoint behaved before.
- Do not tighten existing header handling on shipped endpoints: stricter `Content-Type` matching, newly-enforced `Accept` negotiation, or `User-Agent` requirements all reject callers whose requests worked yesterday.
- Middleware multiplies the mistake. A required-header check added globally converts one feature's requirement into an API-wide breaking change. Scope any enforcement to new endpoints only.
- The legitimate path to a required header: accept-and-log absence first, measure which callers omit it, notify them, and enforce on a deadline by human decision — or require it only in the next API version.
- If the user explicitly asks to require a header, state the consequence precisely — every existing caller fails immediately with 4xx — and propose the optional-with-default or log-then-enforce path.

**Red flags that you're about to violate this:**
- "The tracing system needs a request ID, so requests without one are invalid."
- "Requiring the client version header lets us handle old clients properly."
- "Strict Content-Type checking is just correct HTTP."
- "I'll enforce it in middleware so no endpoint can forget it."
- "It's one header — clients can add it in a minute."
