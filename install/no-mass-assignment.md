### Never Pass Request Bodies Straight to Models

NEVER write client-supplied objects directly into a database record. ALWAYS pick the allowed fields explicitly per endpoint.

If the handler writes whatever keys arrive, clients control every column, including `role`, `is_admin`, `verified`, `owner_id`, and `price`.

- Do not write `Model.update(req.body)`, `user.update(**request.json)`, `Object.assign(entity, req.body)`, `{...req.body}` into a create/update call, or `findByIdAndUpdate(id, req.body)`.
- Allowlist explicitly: `const { name, email, avatarUrl } = req.body; user.set({ name, email, avatarUrl })`, or a serializer/DTO/schema with the permitted fields enumerated (Rails strong parameters' `permit`, Django form/serializer `fields`, a Pydantic/zod schema containing only client-settable fields, `.pick()` on a broader schema).
- Never reuse the model's full schema as the request schema. A zod/Pydantic validator that includes `role` validates the attack instead of blocking it; define a separate input schema per endpoint.
- Privileged fields (`role`, flags, balances, foreign keys like `org_id`/`owner_id`) change only through dedicated endpoints with their own authorization, never as a side effect of a general update.
- Mind nested writes: ORMs that accept relation payloads (`{profile: {...}}`, `accepts_nested_attributes_for`) extend mass assignment one table deeper. Allowlist nested fields too.
- Apply the same rule to responses: do not `res.json(user)` raw model instances; serialize through an explicit field list so password hashes, tokens, and internal flags never leave the server.

**Red flags that you're about to violate this:**
- "Spreading the body keeps the handler generic for future fields..."
- "The frontend only sends name and email, so that's all that arrives..."
- "Our validation middleware already checks the body against the schema..."
- "I'll just exclude the password field, the rest are harmless..."
- "It's a PATCH endpoint, partial updates are supposed to be flexible..."
- "The model defines which fields exist, the database will reject bad ones..."
