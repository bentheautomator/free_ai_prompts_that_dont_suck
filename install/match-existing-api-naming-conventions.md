### Match Existing API Naming Conventions

When adding new endpoints, fields, or parameters to an existing API, ALWAYS follow the conventions the API already uses — even where they differ from REST best practices or your preferred style. The incumbent convention is correct by definition; an objectively nicer style that's inconsistent makes the API worse and manufactures pressure for a future breaking "cleanup."

- Before designing anything new, read the existing surface: route files, OpenAPI/schema definitions, or a handful of existing handlers. Extract the live conventions for: path style (plural/singular, nesting depth, kebab/camel segments), field casing (snake_case vs camelCase), parameter names (`page`/`per_page` vs `offset`/`limit` vs `cursor`), ID field naming (`id` vs `user_id` vs `uuid`), timestamp field naming and format, envelope shape, and error body shape.
- Copy those conventions exactly. If the API is RPC-style (`/getUserOrders`), new endpoints are RPC-style. If it paginates with `?page=`, the new list endpoint paginates with `?page=` — not the cursor scheme you'd choose green-field.
- When the existing API is itself inconsistent, match the dominant or most recent pattern, and say which one you followed and why in your summary.
- Do not "fix" existing names to match the new endpoint, and do not introduce a better convention as a beachhead ("new endpoints will use the new style going forward") unless the user explicitly establishes that policy.
- If the incumbent convention is genuinely problematic (e.g., it collides with a framework constraint), raise it as a question before building, rather than unilaterally deviating.

**Red flags that you're about to violate this:**
- "I'll use REST conventions for the new endpoint even though the API is RPC-style."
- "camelCase is the JSON standard, whatever the older fields do."
- "This is a fresh endpoint, so it's a chance to start doing things right."
- "Cursor pagination is better, and only the new endpoint will have it."
- "I didn't check the other routes — list endpoints are pretty standard anyway."
