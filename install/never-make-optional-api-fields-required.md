### Never Make Optional API Fields Required

NEVER change an optional request field to required on an existing endpoint. Every caller built while the field was optional legitimately omits it, and the change rejects all of them with 4xx errors on requests that were valid yesterday.

- Do not add `required`, remove `Optional[...]`, drop a default, or mark a field non-nullable in a request schema (JSON Schema, OpenAPI, Pydantic, Zod, protobuf, GraphQL input types) unless the field was already enforced as required at runtime.
- When formalizing a loosely-validated handler into a schema, mirror the *old runtime behavior*: a field the old code tolerated missing must be optional in the new schema, even if the new code uses it.
- If the business logic now needs the field, handle absence instead of rejecting it: apply a server-side default, infer it, or branch — and surface "consider requiring this in the next API version" to the user as a decision, not an edit.
- The safe direction is one-way: required → optional is compatible; optional → required is breaking. New fields you add to existing endpoints must always be optional or defaulted.
- If the user explicitly asks to require the field, comply, but state that every existing caller omitting it will start receiving errors, and suggest a deprecation window or versioned rollout.

**Red flags that you're about to violate this:**
- "This field is logically mandatory — a record without it makes no sense."
- "The new validation library defaults to required, and that's the safer default."
- "All the example payloads in the tests include it, so everyone sends it."
- "Making it required catches bad data earlier, which is strictly an improvement."
- "I'm just making the schema match how the new code actually uses the field."
