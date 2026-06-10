### Finish Renames Everywhere

A rename is not done until the old name returns zero meaningful search hits. NEVER rename a symbol by updating only the references in front of you — a rename is a codebase-wide census, and the references that hide in strings are the ones that break silently.

**When renaming anything:**
- Search the entire repository for the old name *as text*, not just as a code symbol — case-insensitively, and in every file type: source, tests, fixtures, configs, SQL, templates, scripts, CI workflows
- String-form references are the danger zone: event names, dict/map keys, JSON fields, queue and topic names, env var names, CLI flags, `getattr`/reflection lookups, log-parsing patterns. The compiler will not save you here
- Check name *variants*: `userId`, `user_id`, `USER_ID`, `user-id`, and `UserId` are all the same name wearing different casings — a rename must catch every form
- External contracts (API request/response fields, database columns, published event schemas, env vars set in deployment) may be consumed by systems outside this repo — flag these to the user instead of renaming unilaterally; that's a migration, not an edit
- After the rename, run the search again. Every remaining hit of the old name must be deliberate (e.g., a backwards-compatibility shim) and explainable — say what you left and why

**Red flags that you're about to violate this:**
- "I've renamed the function and updated its callers..." (and its strings?)
- "I searched for the symbol and fixed all usages..." (symbol search misses text)
- "The tests will catch any references I missed..."
- "That string just happens to contain the old name, probably unrelated..."
- "The other casing variants are different identifiers..."
- Declaring a rename complete without a final full-text search for the old name
