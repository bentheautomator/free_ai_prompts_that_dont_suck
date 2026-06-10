---
title: Keep API Response Envelope Stable
slug: keep-api-response-envelope-stable
category: api-design
tags: [universal, apis, compatibility]
works_with: all
severity: high
one_liner: "Stops adding or removing data wrappers around payloads consumers already parse"
---

# Keep API Response Envelope Stable

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from wrapping a bare response in an envelope, or unwrapping an existing one, and shifting every key consumers read one level.

**[Copy-paste ready version](../../install/keep-api-response-envelope-stable.md)** — just the instruction block, no explanation.

## The Problem

An endpoint returns a bare array: `[{"id": 1}, {"id": 2}]`. The AI, standardizing responses across the API, wraps it: `{"data": [{"id": 1}], "meta": {"count": 1}}`. Or it finds the opposite — an envelope it considers ceremonial — and unwraps it so the payload is "cleaner." Either way, not a single field was renamed, and yet every consumer breaks at once: code that did `response.map(...)` is now mapping over an object; code that read `response.data` now gets `undefined` at the top.

Envelope changes are the whole-payload version of a field rename, but they evade the AI's own caution because no individual field appears in the diff as changed. The serializer change reads as structural housekeeping — often a single decorator, base-class swap, or interceptor — and a one-line change can re-shape forty endpoints simultaneously. Response interceptors and "API response standardization" middleware are the classic delivery vehicle: maximum blast radius, minimum diff.

The AI does it because mixed conventions (some endpoints wrapped, some bare) genuinely look like a defect, and unifying them is the kind of consistency work it's praised for everywhere else in a codebase.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Keep API Response Envelope Stable

NEVER add, remove, or restructure the envelope of an existing endpoint's response — no wrapping bare payloads in `{"data": ...}`, no unwrapping existing envelopes, no renaming envelope keys, no converting a top-level array to an object or vice versa. Moving every field one level deep (or shallower) breaks all consumers at once, exactly like renaming every field simultaneously.

- A mixed API — some endpoints enveloped, some bare — is each endpoint's individual contract, not a defect to unify. Consistency is for endpoints that don't exist yet.
- Top-level array ↔ top-level object is the sharpest version: `response.map(...)` versus `response.data.map(...)` cannot both work, so there is no client that survives the change by accident.
- Beware one-line blast radius: global response interceptors, serializer base classes, and "standardize API responses" middleware change every endpoint's envelope in a single edit. Any such change must explicitly exempt all shipped endpoints.
- Adding *siblings inside* an existing envelope (a new `meta` key next to `data`) is additive and fine. Adding the envelope itself is not. Note: if the response is currently a top-level array, there is nowhere compatible to put metadata — that's a new-version problem, not a wrapping problem.
- If the user wants a uniform envelope, apply it to new endpoints and new API versions, or offer it via opt-in (header or query param) on existing ones, with the default shape unchanged.

**Red flags that you're about to violate this:**
- "Half the endpoints wrap responses and half don't — I'll standardize them."
- "Wrapping in a data key now gives us room for metadata later."
- "The envelope is pure boilerplate; unwrapping simplifies every client."
- "One interceptor fixes the response format everywhere at once."
- "No field names changed, so consumers are unaffected."

---

## Why It Works

1. **It equates envelope changes with renaming every field at once**, importing the caution the AI already has about field renames into a change category where no field appears modified.
2. **It declares mixed conventions a contract, not a defect**, neutralizing the consistency drive that motivates the change in the first place.
3. **It flags the one-line/forty-endpoints asymmetry** of interceptors and base classes, where diff size catastrophically understates contract impact.
4. **It separates adding-inside from adding-around**, giving a precise additive boundary instead of a vague "don't restructure," and names the array-metadata dead end before the AI invents wrapping as its solution.

## Origin

To support pagination metadata "eventually," an assistant added a response interceptor wrapping every JSON payload in `{success, data, timestamp}`. Forty-one endpoints changed shape in a four-line diff. The repo's own frontend was updated in the same PR and looked flawless in review. Two embedded-device clients in the field, which polled three of those endpoints and parsed top-level arrays, failed on their next poll; the devices had no remote-update path and had to be reflashed through a support program. The interceptor was reverted, but the devices didn't know that until someone visited them.
