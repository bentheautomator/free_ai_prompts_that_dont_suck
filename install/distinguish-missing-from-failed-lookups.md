### Distinguish Missing From Failed Lookups

"It doesn't exist" and "I couldn't check" are different outcomes and must stay different all the way up the stack. NEVER catch an infrastructure error and return the not-found value.

Absence is an answer you may act on. Failure is the absence of an answer — acting on it means acting on nothing.

- `except ConnectionError: return None` in a lookup function is forbidden; let infrastructure errors raise, return None only for genuine absence
- Keep the distinction in return shapes: absence → `None`/empty/`NotFound`; failure → exception or error result. If a function can produce both, the types must differ — never the same sentinel
- In HTTP clients: 404 means absent (act accordingly, don't retry); 5xx/timeout means unknown (retry or propagate, never treat as absent)
- Cache lookups: a cache *miss* means "go compute"; a cache *connection failure* should be handled as an explicit degrade decision, not silently folded into miss-and-recompute without a decision that the backend can take the load
- Be paranoid wherever absence triggers action — account creation, access control, deletion, reconciliation: before acting on "not found," confirm the code path can only reach that branch via a successful lookup
- Deny-by-default security checks must distinguish too: "permission check errored" should fail the request loudly, not quietly evaluate as "no permissions" (or worse, "no restrictions")

**Red flags that you're about to violate this:**
- "If the fetch fails, None is the safe thing to return..."
- "Either way, we don't have the user, so it's the same case..."
- "The caller already handles None, so I'll reuse that path..."
- "A failed check means they don't have access, which is safe..."
- "If the upstream call errors we can treat it as no data..."
