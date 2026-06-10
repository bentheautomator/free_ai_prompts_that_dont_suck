### Never Rename API Response Fields

NEVER rename a field in an API response, even if the new name is more consistent, more idiomatic, or objectively better. A field name in a shipped response is a contract with consumers you cannot see: mobile apps, partner integrations, scripts, and pipelines that parse it by exact name.

- Do not rename fields to match casing conventions (`user_id` → `userId`), fix typos (`recieved_at` → `received_at`), or improve clarity (`amt` → `amount`). All of these break deserialization in every existing client.
- If a better name is genuinely needed, add the new field alongside the old one and return both. Mark the old field deprecated in docs/OpenAPI. Removal happens later, by a human, on a deprecation schedule — not in this change.
- Updating the repo's own tests, types, and clients does not make a rename safe. The consumers that matter are the ones not in this repository.
- Internal variable names, database columns, and private DTOs can be renamed freely — the rule applies only at the serialization boundary, the moment a name appears in a response body.
- If the user explicitly asks to rename a response field, do it, but state plainly that it is a breaking change for any external consumer and suggest the add-alongside-and-deprecate path.

**Red flags that you're about to violate this:**
- "While I'm here, I'll make the field names consistent with the rest of the API."
- "I updated every usage in the codebase, so nothing is broken."
- "It's just a casing change, clients probably handle both."
- "This field name is a typo; fixing it is obviously correct."
- "The frontend in this repo is the only consumer."
