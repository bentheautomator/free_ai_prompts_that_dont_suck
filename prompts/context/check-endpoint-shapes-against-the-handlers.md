---
title: Check Endpoint Shapes Against the Handlers
slug: check-endpoint-shapes-against-the-handlers
category: context
tags: [universal, verification, assumptions]
works_with: all
severity: high
one_liner: "AI guessing the app's API routes and JSON shapes instead of reading handlers"
---

# Check Endpoint Shapes Against the Handlers

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from inventing this project's API routes, payloads, and response shapes from REST convention.

**[Copy-paste ready version](../../install/check-endpoint-shapes-against-the-handlers.md)** — just the instruction block, no explanation.

## The Problem

Asked to write a client call for "the users endpoint," the AI produces textbook REST: `GET /api/users/:id` returning `{ id, name, email }`, errors as `{ error: "message" }` with proper status codes. This project's actual endpoint is `POST /api/v2/user.fetch` (someone liked RPC styles), the response wraps everything in `{ ok, data, meta }`, the id field is `userId`, and errors come back as HTTP 200 with `ok: false` — a decision people have argued about in three retros. The AI wrote a client for an API that exists only in tutorials.

Internal APIs diverge from convention everywhere it matters: route naming, envelope shapes, pagination styles (cursor vs offset vs page), field casing (camelCase vs snake_case — often inconsistent across endpoints of different ages), auth header formats, error contracts. Frontend code written against guessed shapes fails in the most annoying way — at runtime, field by field — `response.data.items` is undefined because it's actually `response.body.results`, and each undefined is its own little debugging session.

The contract is in the repo, twice: the handler code that serializes the response, and often a schema (OpenAPI spec, GraphQL SDL, tRPC router, zod schemas) that exists precisely so nobody has to guess.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Check Endpoint Shapes Against the Handlers

NEVER write code against this project's own API from REST convention or intuition. Internal APIs diverge from the textbook in routes, envelopes, field names, pagination, and error contracts — and the actual contract is sitting in the repo.

A guessed shape fails at runtime, one undefined field at a time, each one its own debugging session.

**Before writing any call against a project endpoint:**
- Find the contract's best source, in order: a schema if one exists (OpenAPI/Swagger spec, GraphQL SDL, tRPC/ts-rest routers, zod/joi response schemas, generated API clients), else the handler itself
- Read what the handler actually serializes — the return statement or response builder, including the envelope (`{ data }`? `{ ok, data, meta }`? bare object?) and exact field names with their casing
- Check the error contract separately: status codes used, error body shape, and whether failures can arrive as 200s — error handling written for the wrong contract silently swallows failures
- Confirm route, method, and auth from the router/middleware: path prefixes (`/api/v2`), the actual verb, required headers — not from what a RESTful design would choose
- Look for an existing client call to the same endpoint elsewhere in the codebase and match it — prior art beats both convention and your reading of the handler
- For pagination, match the project's actual mechanism (cursor, offset, page/perPage, Link headers) — pagination is where guessed shapes die quietly

**Red flags that you're about to violate this:**
- "It'll be a standard REST endpoint: GET /api/users/:id..."
- "The response will have the obvious fields..."
- "Errors will come back as 4xx with an error message..."
- "I'll assume camelCase, it's a JS project..."
- "Pagination is probably page and limit params..."
- Writing `response.data.something` for an endpoint whose handler you never read

---

## Why It Works

1. **It severs the REST-tutorial prior.** Naming the divergence dimensions (envelope, casing, pagination, errors-as-200s) shows the AI exactly where its textbook instincts will be wrong, making "standard REST" feel like the guess it is.

2. **It orders the evidence sources.** Schema beats handler beats convention; existing client calls beat everything. The hierarchy gives a deterministic lookup path instead of a vague "check the API."

3. **It isolates the error contract.** Happy-path verification leaves error handling guessed — and wrong error handling doesn't fail visibly, it swallows. Splitting it out forces the second look.

4. **It elevates prior art.** Another call site to the same endpoint encodes the contract *as consumed*, including quirks the handler read might miss — and matching it keeps client code consistent besides.

## Origin

A frontend AI wired a new dashboard to the team's metrics endpoint, assuming offset pagination with `page` and `limit`. The API used cursor pagination and ignored unknown query params — so every "page" silently returned the same first 50 rows. The dashboard shipped, demos went fine, and for three weeks every user who clicked past page one saw page one again with different page numbers. A customer eventually asked why their data stopped at exactly 50 records, and the resulting fix commit message read: "the API and the client have now been introduced to each other."
