---
title: Match Existing Response Shapes
slug: match-existing-response-shapes
category: code-quality
tags: [universal, apis, patterns]
works_with: all
severity: high
one_liner: "AI returning a new payload shape in an API that has a standard envelope"
---

# Match Existing Response Shapes

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from inventing a new response format for one endpoint in an API where every other endpoint shares a shape.

**[Copy-paste ready version](../../install/match-existing-response-shapes.md)** — just the instruction block, no explanation.

## The Problem

Every endpoint in the service returns `{ "data": ..., "error": null, "meta": {...} }`. Pagination is always `meta.cursor`. Errors are always `{ "error": { "code", "message" } }` with the HTTP status mirrored inside. Then an AI adds one new endpoint and returns... a bare array. Errors come back as `{ "detail": "..." }` because that's what the model's favorite framework does by default. Pagination, if it exists, is `?page=2` in a cursor-paginated API.

The AI does this because it generates endpoints from its training-data prior, not from your API's contract — and framework defaults (FastAPI's `detail`, Rails' bare render, Express's whatever-you-pass) are heavily reinforced in that prior. The damage lands client-side: every consumer has generic unwrapping code (`response.data`, shared error interceptors, typed envelope parsers) that the new endpoint breaks. Mobile clients crash on the missing envelope; the web app's error toast shows `undefined` because the error shape didn't match the interceptor. One inconsistent endpoint converts "clients handle responses generically" into "clients special-case endpoint by endpoint," and that never converts back.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Match Existing Response Shapes

NEVER design a response shape for a new endpoint. The API already has one — find it and conform. Same rule for inputs: request body conventions, query parameter naming, and pagination style are inherited, not chosen per endpoint.

Clients consume this API generically through shared unwrappers and error interceptors. An endpoint with its own shape breaks every one of those, and turns uniform client code into per-endpoint special cases.

**Before writing any new endpoint or handler:**
- Read 2-3 existing endpoints — ideally the most recently written ones — and extract the contract: envelope structure, error format, status code usage, pagination scheme, field casing (camelCase vs snake_case), timestamp format, null vs absent-field conventions
- Reuse the existing serializers, response builders, presenter classes, or schema types rather than constructing response dicts/objects inline — if a `make_response()` helper or base serializer exists, that's the API contract in code form
- Your framework's default error format is not the API's error format unless the codebase demonstrably uses it — check how existing handlers return errors before letting the framework answer for you
- Errors conform too: same envelope, same code/message structure, same status-code conventions as the rest of the API
- If the requested feature genuinely can't fit the existing shape, say so and ask — don't quietly ship the exception

**Red flags that you're about to violate this:**
- "I'll return the list directly, simple and clean..."
- "The framework's standard error response is fine here..."
- "I'll add page/limit params for pagination..." (in a cursor-paginated API)
- "Building the response inline is more readable than their serializer machinery..."
- "snake_case is more standard for JSON..." (in a camelCase API)
- Writing a handler without having read what any sibling endpoint returns

---

## Why It Works

1. **It removes a design decision the AI didn't know it was making.** The model experiences "return the result" as neutral; framing the shape as a pre-existing contract makes visible that *any* shape choice is either conformance or violation.

2. **It dethrones framework defaults.** FastAPI's `detail` and friends carry massive training-data weight, so the AI treats them as correct. Explicitly subordinating them to the codebase's observed format breaks that pull.

3. **It routes through the serializer layer.** Reusing response builders makes conformance structural — the helper *can't* produce the wrong envelope — instead of relying on the AI to imitate a shape field by field.

4. **It names the client-side blast radius.** "Inconsistent" undersells the cost; "breaks every shared interceptor" prices it correctly, which is what makes the AI spend the read.

## Origin

A new search endpoint went out returning a bare JSON array in an API where everything else wrapped results in a `data` envelope. The mobile app's shared response parser threw on the missing wrapper, but only on the screen using search — which had shipped to app stores before anyone noticed. The web client was patched in an hour; the mobile fix waited eight days in app-store review while support fielded crash reports, all because one endpoint freelanced its shape.
