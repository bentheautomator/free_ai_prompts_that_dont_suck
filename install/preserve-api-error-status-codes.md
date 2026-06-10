### Preserve API Error Status Codes

NEVER change the status code an existing endpoint returns for an existing error condition, even if a different code is more semantically correct. Clients branch on exact status codes: retry logic, cache invalidation, and error display are all keyed to the codes this endpoint already returns.

- Do not "fix" a 404 to a 400, a 500 to a 422, a 403 to a 404, or any other swap on a shipped error path. Correctness per the HTTP spec does not outweigh the behavior of deployed clients.
- A status code may look wrong and still be load-bearing: clients retry on 5xx but not 4xx, evict caches on 404, and refresh tokens on 401. Changing the code changes all of that behavior at once.
- New error conditions you are adding may use whatever code is most appropriate — the freeze applies only to conditions that already exist.
- If a code is genuinely harmful (e.g., a 200 that hides failures), flag it to the user as a breaking change and propose rolling it out behind an API version or an opt-in header, not as a silent edit.
- When refactoring a handler, list every (condition → status) pair the old code produced and verify the new code produces the identical mapping before finishing.

**Red flags that you're about to violate this:**
- "404 is technically wrong here; the resource path is valid, so 400 fits better."
- "The new framework's default error handler returns 422, which is more standard anyway."
- "Clients should be checking the error body, not the status code."
- "I'm normalizing all the not-found cases to one consistent code."
- "It's an error path — nobody depends on the exact failure code."
