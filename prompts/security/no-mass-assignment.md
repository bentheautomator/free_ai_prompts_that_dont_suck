---
title: Never Pass Request Bodies Straight to Models
slug: no-mass-assignment
category: security
tags: [universal, security, auth]
works_with: all
severity: critical
one_liner: "AI spreading req.body into updates, letting users set isAdmin"
---

# Never Pass Request Bodies Straight to Models

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents mass assignment: AI writing update handlers where clients can set any column they name.

**[Copy-paste ready version](../../install/no-mass-assignment.md)** — just the instruction block, no explanation.

## The Problem

The update-profile endpoint needs to handle name, email, and avatar, so the AI writes the general version: `User.update(req.body)`, `user.update(**request.json)`, `Object.assign(user, req.body)`, or a Mongoose `findByIdAndUpdate(id, req.body)`. Elegant. Handles future fields automatically. Also lets any client who reads your API responses add `"role": "admin"`, `"email_verified": true`, `"balance": 99999`, or `"org_id": 2` to their PATCH request, because the handler writes whatever keys arrive. Mass assignment is the bug that famously let a researcher commit to a major framework's own repository by setting a foreign key on a public endpoint.

AI assistants generate this shape eagerly because it minimizes code and maximizes generality, two things models optimize for. The vulnerability is invisible in testing: legitimate clients only send legitimate fields, so every test passes and the demo works. The fields at risk are exactly the ones nobody sends in tests — role flags, ownership keys, verification status, prices, internal counters.

The same flaw applies on the way out: `res.json(user)` serializes password hashes and 2FA secrets to anyone who can read the response. Both directions need an explicit allowlist of fields, chosen per endpoint.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

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

---

## Why It Works

1. **It attacks the generality instinct.** The AI sees field-by-field assignment as repetitive code to be abstracted away. Framing the explicit list as the security control reframes the "improvement" as the bug.

2. **It closes the schema-reuse loophole.** "I validated with the model schema" feels like compliance while permitting `role`. Requiring a separate per-endpoint input schema is the precise correction.

3. **It pairs input and output.** The same allowlist blindness leaks password hashes via `res.json(user)`. Handling both directions in one rule catches the half of the bug most instructions miss.

4. **It assigns privileged fields a different mechanism entirely.** Saying "denylist `role` on this endpoint" invites drift; saying privileged fields get their own authorized endpoints removes them from the attack surface of every general update.

## Origin

A subscription service's profile endpoint spread the request body into the user document. The `plan` and `credits_remaining` fields lived on the same document, a detail visible in the API's own GET response. A user added `"credits_remaining": 100000` to their profile update and used the service free for months; logs showed dozens of others had quietly done the same. The fix enumerated three writable fields and moved billing mutations behind the payment webhook where they belonged.
