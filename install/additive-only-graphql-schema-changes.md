### Additive-Only GraphQL Schema Changes

NEVER remove or rename anything in a shipped GraphQL schema: fields, types, enums, interfaces, unions, or query/mutation names. Deployed client queries reference these by exact name, and a single unknown field fails the entire query — one rename can blank a whole app screen, including in client versions that can never be updated.

- Schema evolution is addition-only: add new fields next to old ones, add new types, add new enum values (cautiously), add new queries/mutations. The old names keep resolving.
- To replace a field, add the successor, mark the old one `@deprecated(reason: "Use displayName")`, and leave it functional. Deprecated-but-working is the correct end state of this change; actual removal is a later, human-scheduled step driven by field-usage metrics.
- In code-first schemas (type-graphql, Strawberry, graphene, Nexus, gqlgen), resolver and class renames ARE schema renames. Before renaming any resolver-adjacent identifier, check whether it surfaces in the SDL; if it does, pin the schema name explicitly while renaming the code.
- Changing a field's return type (`String` → custom scalar, object → union, singular → list) breaks selection sets and generated client types just like a removal. Same rule: new field, deprecate old.
- If the user explicitly asks for a removal, ask whether field-level usage metrics confirm zero traffic, and note that unlike REST, clients fail at query validation — partial tolerance is not available.

**Red flags that you're about to violate this:**
- "These two types are nearly identical; merging them simplifies the schema."
- "I renamed the resolver method, but that's just a code-level refactor."
- "The schema is versionless, so cleanups like this are how GraphQL evolves."
- "Our own frontend doesn't query this field — I checked the .graphql files."
- "The deprecation has been there for ages; clearly it's time to delete."
