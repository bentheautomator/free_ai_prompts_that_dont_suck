---
title: Never Make Optional API Fields Required
slug: never-make-optional-api-fields-required
category: api-design
tags: [universal, apis, compatibility]
works_with: all
severity: high
one_liner: "Stops promoting optional request fields to required, rejecting old callers"
---

# Never Make Optional API Fields Required

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from making a previously-optional request field mandatory, instantly rejecting every caller that was built without it.

**[Copy-paste ready version](../../install/never-make-optional-api-fields-required.md)** — just the instruction block, no explanation.

## The Problem

Somewhere in a request schema sits `phone_number: optional`. The AI is adding a feature that uses phone numbers, notices the field "should really always be present," and flips it to required. Or it's translating a loose hand-rolled handler into Pydantic, Zod, or JSON Schema and marks fields required because the new code path happens to read them. The schema now looks complete and self-documenting. It is also a tripwire.

Every existing caller that omits the field — and they omit it precisely because it was optional — now gets a 400 on a request that worked yesterday. These aren't edge cases; they're the integrations built correctly against the contract as it stood. A mobile app version shipped last quarter can't add a field retroactively. The callers have no bug to fix and no warning before they break.

Assistants do this because requiredness looks like a data-quality improvement, and the schema file is the only place the decision seems to live. The set of payloads actually in flight — the ones missing the newly-required field — is invisible to a code-level view.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

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

---

## Why It Works

1. **It states the asymmetry as a rule of physics** — required→optional safe, optional→required breaking — which gives the AI a direction-check it can apply mechanically in any schema language.
2. **It targets the schema-formalization moment**, the highest-risk context: the AI converting loose validation into strict schemas genuinely believes it's documenting, not changing, the contract.
3. **It redirects the data-quality impulse** into server-side defaults and version proposals, so the AI's "this should always be present" instinct produces compatible code instead of rejections.
4. **It defines the contract as old runtime behavior, not new code needs**, removing the loophole where the new implementation's requirements justify tightening the interface.

## Origin

While porting an endpoint from hand-rolled checks to a typed schema, an assistant marked `company_name` required because every test fixture included it. Individual (non-business) accounts had always omitted the field, and that entire signup segment began failing with validation errors within minutes of deploy. The fix was a one-word revert; finding it took hours, because the deploy's stated purpose was "no functional changes, just schema validation."
