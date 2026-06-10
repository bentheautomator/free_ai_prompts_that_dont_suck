### Freeze API Default Query Behavior

NEVER change what an existing endpoint returns when a parameter is omitted. The no-parameter request is its own contract: every existing caller sends it, and a new or changed default rewrites all of their results at once without a single error.

- When adding a new filter, flag, or scope parameter to an existing endpoint, its default MUST reproduce the endpoint's current behavior exactly — even when that default looks wrong. If the endpoint returned archived rows before, `include_archived` defaults to `true`.
- Never flip an existing default (`include_deleted`, `expand`, `status`, default date ranges) on a shipped endpoint, and never narrow an endpoint's implicit scope (all records → current user's records) outside an explicit, user-approved breaking change.
- A request with no params returning a 200 is not evidence of compatibility. The contract is the *content*: same records, same scope, same filters as before the change.
- If the current default is genuinely dangerous or wrong, present the fix as a breaking change: new API version, new endpoint, or a deprecation window with announced default-flip date. Not a silent edit.
- After adding any parameter, state in your summary what a parameter-less request returned before and after. They must match.

**Red flags that you're about to violate this:**
- "Excluding archived items by default is what most callers would expect."
- "The old default was a footgun; defaulting to the safe value fixes it."
- "Callers who want the old behavior can just pass the flag."
- "I'm only adding a parameter — omitting it is handled gracefully."
- "Scoping the list to the current user is more secure, so it's an improvement."
