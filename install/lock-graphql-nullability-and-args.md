### Lock GraphQL Nullability and Arguments

NEVER change nullability markers (`!`) on existing GraphQL fields, and NEVER add required arguments or required input-type fields to shipped queries and mutations. Both directions of a nullability flip break consumers, and required additions invalidate every deployed operation that predates them.

- Nullable → non-null (`String` → `String!`) is a runtime bomb: the first resolver null triggers non-null propagation, erroring the parent selection or the whole response for all clients because of one bad record.
- Non-null → nullable (`String!` → `String`) breaks generated client types in every consumer that runs codegen, and deployed clients built against non-null crash on the first null they were promised would never come.
- New arguments on existing fields/queries must have defaults or be nullable. New fields on existing input types must be optional. Deployed operations are frozen text — often in persisted-query allowlists — and cannot retroactively send anything.
- Tightening an input the resolver genuinely needs is done in the resolver: validate at runtime, return a typed error for new violations, and keep the schema signature stable. Schema-level tightening waits for a new field or schema version.
- If asked to "make the schema match reality" by adding `!`, first confirm the data can never be null (including legacy rows and failure paths), and present the flip to the user as a breaking change for codegen consumers regardless.

**Red flags that you're about to violate this:**
- "This field is never actually null, so marking it non-null just documents reality."
- "Codegen consumers will simply regenerate their types — that's what codegen is for."
- "The mutation needs this argument now; old clients should be passing it anyway."
- "Loosening to nullable can't break anyone — it accepts strictly more."
- "It's a one-character schema change."
