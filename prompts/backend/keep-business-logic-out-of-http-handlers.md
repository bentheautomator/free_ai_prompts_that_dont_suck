---
title: Keep Business Logic Out of HTTP Handlers
slug: keep-business-logic-out-of-http-handlers
category: backend
tags: [universal, backend]
works_with: all
severity: medium
one_liner: "Keeps business rules callable from anywhere, not welded to one route"
---

# Keep Business Logic Out of HTTP Handlers

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents core business rules from being buried inside route handlers where they can't be tested, reused, or called from anywhere but HTTP.

**[Copy-paste ready version](../../install/keep-business-logic-out-of-http-handlers.md)** — just the instruction block, no explanation.

## The Problem

Ask an assistant to "add an endpoint that creates an order" and it produces one function: parse the request, validate, check inventory, calculate pricing, apply the discount rules, write three tables, send the confirmation email, format the response. Two hundred lines, all inside `POST /orders`. It works, it's all in one place, and the demo is convincing. The assistant builds it this way because a single function is the smallest unit that satisfies the prompt — separation of concerns is never required by "make the endpoint work."

The cost arrives on the second caller. The CSV import needs to create orders: it can't call a route handler, so the logic gets copy-pasted into the import job. The queue consumer needs to create orders: third copy. The admin panel: fourth. Now the discount rules exist in four places, and when legal changes the tax rounding, three of them get updated. The handler version drifts from the worker version, and you debug "why are imported orders priced differently?" for a day. Meanwhile, testing the pricing rules requires constructing fake HTTP requests and asserting against JSON, so the tests are slow, shallow, and mostly skipped.

This isn't an aesthetic preference. Handler-monoliths are how duplicated business rules, untestable cores, and "we can't add a CLI for that without a refactor" happen.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Keep Business Logic Out of HTTP Handlers

HTTP handlers translate; they do not decide. A handler's whole job is: parse/validate input, call one domain function, map the result (including domain errors) to a status code and response body. Business rules live in plain functions or service objects that know nothing about HTTP.

- Put the rules in a transport-free layer: `orderService.createOrder(input) -> Order | DomainError`, taking plain typed inputs and returning plain results. No `req`/`res`, no status codes, no headers, no framework imports in that layer.
- Domain functions signal outcomes with typed errors or result values (`InsufficientInventory`, `DiscountExpired`); the handler — and only the handler — maps those to 409, 422, or whatever the API contract says.
- Every other entry point (queue consumers, cron jobs, CLI commands, gRPC, test code) calls the same domain function. If a rule would have to be copy-pasted to be reused, it's in the wrong layer.
- Keep transport concerns in the handler: deserialization, content negotiation, auth extraction (pass the resulting identity in, not the token), response shaping. Keep persistence behind the domain layer, not spliced into the route.
- Unit-test business rules by calling the function with values — no test server, no JSON fixtures. Handler tests then only need to cover translation.
- Heuristic: a handler longer than ~30 lines, or containing a conditional about money/permissions/inventory, is hiding domain logic. Extract it.

**Red flags that you're about to violate this:**
- "It's simpler to keep it all in the route."
- "Nothing else will ever need to create an order."
- "I'll extract it when there's a second caller." (The second caller copy-pastes instead.)
- "Adding a service layer is enterprise-y boilerplate."
- "I'll just import the handler from the worker and fake a request object."
- "The framework encourages fat controllers, look at the examples."

---

## Why It Works

1. **It pre-empts the copy-paste fork.** The duplication doesn't happen at refactor time, it happens the day a non-HTTP caller appears and the logic is unreachable. Extracting at write time costs minutes; extracting after three forks costs a reconciliation project.
2. **It makes the core testable at function speed.** Rules tested as `f(input) == output` get hundreds of fast cases; rules tested through a test server get five slow ones. Coverage follows friction.
3. **It gives errors two clean halves.** Typed domain outcomes mapped to status codes in one place ends both scattered `res.status(409)` calls in business code and business `if`s in handlers.
4. **It states the handler's job positively.** "Parse, call one function, map the result" is a checkable spec; "don't put logic in handlers" alone just invites a debate about what counts as logic. The 30-line heuristic settles the debate mechanically.

## Origin

A subscriptions API computed proration inside the `PATCH /subscriptions/:id` handler. Within a year the same math had been re-implemented in a Stripe webhook consumer, a billing backfill script, and an admin tool — each copy slightly different. A pricing change updated two of the four; for six weeks, upgrades initiated from the admin panel were prorated under last year's rules, costing real revenue per upgrade. The fix extracted one `prorate()` function and deleted three handlers' worth of arithmetic; the four call sites have agreed ever since.
