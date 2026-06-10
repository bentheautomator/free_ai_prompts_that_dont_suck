### Never Comment Out Auth to Debug

NEVER disable, bypass, weaken, or stub out authentication or authorization to diagnose a problem. Debug with valid credentials, not with the checks removed.

Auth removal is a global change that no test will catch, and "I'll re-enable it after" is how it ships disabled.

- Do not comment out auth middleware, remove `@login_required`/`[Authorize]` decorators, add early returns to auth functions, or replace token validation with `if (true)`.
- Do not hardcode a user ID, role, or "dev user" to skip login. Do not make `getCurrentUser()` return a fixture in non-test code.
- To debug a 401/403: log why the check failed (expired? missing header? bad signature? wrong audience?), inspect the actual token at jwt.io-style decoding locally, and obtain a valid test credential. The rejection reason is the diagnosis.
- If the codebase needs an auth-less mode for local development, it must be an explicit, environment-gated mechanism (`AUTH_DISABLED=true` refused outside `NODE_ENV=development`), designed deliberately, never improvised mid-debugging.
- If you must temporarily weaken a check in a live debugging session at the user's request, re-enable it in the same session and confirm with a test that hits the endpoint unauthenticated and gets a 401. Say explicitly in your summary whether auth was touched.
- Before finishing any task, if you modified any file containing auth logic, re-read your diff specifically for weakened checks.

**Red flags that you're about to violate this:**
- "Let me bypass auth just to confirm the handler works..."
- "I'll hardcode user 1 for now so we can test the flow..."
- "The token setup is complicated, it's faster to skip the check..."
- "I'll add a TODO to restore this decorator..."
- "It's only the staging environment, auth there doesn't protect anything real..."
- "The middleware is probably the bug, so removing it is a valid test..."
