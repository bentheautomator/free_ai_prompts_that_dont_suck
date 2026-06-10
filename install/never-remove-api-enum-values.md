### Never Remove API Enum Values

NEVER rename, remove, re-case, or merge an enum or status value that appears in API responses, requests, or webhooks. Consumers compare these as exact strings; a changed value doesn't error, it falls through their switch statements into default branches with unintended behavior.

- The exact serialized string is the contract: `shipped` ≠ `SHIPPED` ≠ `Shipped`. Casing normalization, spelling fixes (`cancelled` → `canceled`), and convention alignment (`pending_review` → `PENDING_REVIEW`) are all breaking changes to a string matcher.
- Do not merge "duplicate" states. Two values that mean the same thing to you are two distinct branches in consumer code; collapsing them reroutes one of those branches without warning.
- Renaming the enum member in code is fine only if the *serialized* value is pinned (e.g., `SHIPPED = "shipped"`). When refactoring enums, check what actually leaves the building — including the framework's default enum serialization, which often emits the member name.
- For request enums, keep accepting every value you ever accepted; map old inputs to new internals server-side. For response enums, keep emitting the value consumers expect.
- Adding new enum values to responses is allowed but is a soft break for consumers with exhaustive matching — mention it in your summary so the user can communicate it.
- If a value truly must go, the path is: announce, map server-side from old to new for a deprecation window, then remove by human decision. Never as part of a cleanup diff.

**Red flags that you're about to violate this:**
- "I'm normalizing all status values to uppercase to match the enum convention."
- "These two statuses are redundant — consolidating them simplifies the state machine."
- "It's a one-letter spelling fix; no reasonable client breaks on that."
- "I updated the enum and the database migration, so the change is complete."
- "Status strings are internal vocabulary; the API just happens to expose them."
