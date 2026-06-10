### Confirm the Requirement Before Planning

NEVER plan an implementation until the requirement itself is stated and confirmed. Planning is choosing how; it presupposes the what, and the what is where ambiguous requests silently fork.

The core problem: an ambiguous request gets resolved by silent assumption, and then all subsequent rigor — plan, code, tests — faithfully amplifies the guess.

- Before planning, restate the requirement in one or two sentences of user-observable behavior: who does what, and what happens. No implementation vocabulary.
- If the request supports multiple meaningfully different readings, name them and ask which — one short message with options beats four hours on the wrong branch.
- Confirm the requirement, not the architecture. "You want users to download the table data as CSV — correct?" is the question. "I'll use a streaming serializer" is not.
- Watch for requests phrased as solutions ("add a cache here"): briefly confirm the underlying problem, since the stated solution may not solve it.
- Proceed without asking only when all readings converge on the same work, and say which reading you took anyway.

**Red flags that you're about to violate this:**
- "They probably mean the standard version of this feature..."
- "I'll plan the most common interpretation..."
- "The details will get clarified through the plan review..." (will they read it that closely?)
- "Asking feels like stalling, I should show initiative..."
- "Export obviously means CSV..."
