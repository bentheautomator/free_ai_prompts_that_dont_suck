---
title: Keep API Array vs Object Shapes
slug: keep-api-array-vs-object-shapes
category: api-design
tags: [universal, apis, compatibility]
works_with: all
severity: high
one_liner: "Stops flipping fields between single object and array on shipped payloads"
---

# Keep API Array vs Object Shapes

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from changing whether a field or response holds a single object or an array of them — in either direction — on payloads consumers already parse.

**[Copy-paste ready version](../../install/keep-api-array-vs-object-shapes.md)** — just the instruction block, no explanation.

## The Problem

Cardinality changes are shape changes, and AI assistants make them whenever the data model evolves. A user gains support for multiple addresses, so `"address": {...}` becomes `"addresses": [{...}]` — or worse, keeps the name and becomes `"address": [{...}]`. A lookup endpoint that returned a bare object starts returning a one-element array "for uniformity with the list endpoint." Or the reverse optimization: a query that can only ever match one record gets its array unwrapped to a naked object, because the array "was always redundant."

No consumer survives either direction by accident. Code written for an object does `payload.address.city` and now reads `undefined` off an array; code written for an array calls `.map()` on an object and throws. Typed deserializers reject the payload outright. And the one-element-array cases breed a uniquely nasty bug: if the AI changes the shape *conditionally* — object when one result, array when several — every consumer works in testing (where there's one record) and breaks in production (where there are two).

The AI does this because cardinality lives in the data model, and when the model says "this is plural now," propagating that plurality to the wire feels like correctness rather than what it is: a unilateral rewrite of every consumer's parsing assumptions.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Keep API Array vs Object Shapes

NEVER change whether an existing API field or response body is a single object or an array — in either direction. Object-expecting code reads properties off arrays and gets undefined; array-expecting code maps over objects and throws; typed deserializers reject the payload entirely. There is no consumer that tolerates this change by accident.

- When a singular concept becomes plural in the data model (one address → many addresses), keep the shipped singular field exactly as it was — populated with the primary/first value — and ADD a plural field alongside it (`address` stays an object; `addresses` is the new array).
- Never unwrap a one-element array to a bare object ("it can only ever be one") or wrap a bare object into an array ("for consistency with the list endpoint"). Top-level response shapes count double: array ↔ object at the root breaks literally every caller's first line of parsing.
- NEVER make the shape conditional on cardinality — object when one result, array when many. This is the worst variant: it passes every single-record test and fails on the first multi-record response in production.
- Watch serializer defaults: some XML-to-JSON and ORM-relation serializers emit an object for one child and an array for several. Pin the shape explicitly.
- If the user explicitly asks to change a field's cardinality in place, state that both strict and loose consumers break immediately, and propose the keep-singular-add-plural path or a new API version.

**Red flags that you're about to violate this:**
- "Users can have multiple addresses now, so the field should be an array."
- "It returns at most one record — the array wrapper is pointless."
- "Returning an array only when there are multiple results handles both cases neatly."
- "I'll make the detail endpoint match the list endpoint's shape."
- "Consumers can check Array.isArray — it's one line of defensive code."

---

## Why It Works

1. **It asserts that no consumer survives by accident** — for most contract changes the AI can imagine a tolerant client; stating that both strict and loose parsers fail here removes the imagined survivor.
2. **It singles out conditional cardinality as the worst variant**, because it's the option that *looks* most considerate and is the only one guaranteed to pass tests and fail in production.
3. **It pre-builds the correct evolution** (singular field frozen, plural field added), so the data model's genuine pluralization has somewhere compatible to go.
4. **It names the serializer-default trap**, where the shape flip is emitted by tooling rather than written by anyone, and would never appear in a review of the AI's own logic.

## Origin

Supporting multiple payment methods per account, an assistant changed `"payment_method": {...}` to an array under the same key and updated the in-repo frontend flawlessly. A dunning service owned by another team read `payment_method.expiry_date` to warn customers of expiring cards; it began reading undefined for every account, concluded no cards were expiring, and went quiet. The silence was noticed six weeks later via a spike in involuntary churn from expired cards nobody had warned — a failure whose root cause was, in its entirety, one field changing from `{}` to `[{}]`.
