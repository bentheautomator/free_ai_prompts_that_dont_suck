---
title: Make Retried Service Handlers Idempotent
slug: make-retried-service-handlers-idempotent
category: backend
tags: [universal, backend, idempotency]
works_with: all
severity: critical
one_liner: "Stops double charges when clients and proxies retry mutating requests"
---

# Make Retried Service Handlers Idempotent

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents handlers that perform a mutation twice when the same request arrives twice.

**[Copy-paste ready version](../../install/make-retried-service-handlers-idempotent.md)** — just the instruction block, no explanation.

## The Problem

Ask an AI assistant for a `POST /charge` endpoint and you get exactly what you asked for: parse the body, call the payment provider, insert a row, return 200. Run that in production and the mobile client times out on a slow network, retries, and the customer is charged twice. The handler did nothing wrong by its own logic — it was simply called twice with the same intent, and it had no way to know.

Assistants write non-idempotent mutation handlers by default because in a dev environment nothing ever retries. There is no flaky LTE connection, no load balancer re-dispatching after a timeout, no retry-wrapped service mesh. The happy path executes once, the test passes, and the duplicate-execution case literally cannot occur on a laptop.

The fix is boring and mechanical — accept an idempotency key, record it atomically with the mutation, and return the stored result on replay — but it has to be designed in. Bolting it on after the first double-charge incident means a refund queue and an apology email.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Make Retried Service Handlers Idempotent

NEVER write a handler that performs a non-idempotent mutation (charge, send, create, increment) without a mechanism to detect and absorb duplicate requests. Networks retry. Clients retry. Load balancers retry. Assume every mutating request will arrive at least twice.

- Accept an idempotency key (header or body field) on every mutating endpoint that creates side effects. If the caller is internal, derive one deterministically (e.g. `order_id + action`).
- Persist the key in the same atomic operation as the mutation — a unique constraint on the key, not a read-then-write check. `SELECT then INSERT` has a race window; `INSERT ... ON CONFLICT` does not.
- On a duplicate key, return the stored result of the first execution with the same status code — not an error. The retrying client should be unable to tell it was a replay.
- Pass the idempotency key through to downstream providers that support it (payment APIs, email APIs) so the protection extends past your own database.
- Don't fake idempotency with "check if a similar record exists in the last 5 minutes" heuristics. Time windows are not identity.
- Naturally idempotent operations (set status to X, PUT full resource) don't need keys — but verify they actually are, including any side effects they trigger.

**Red flags that you're about to violate this:**
- "The client will only call this once."
- "The frontend disables the button after submit, so duplicates can't happen."
- "I'll check if the record exists first, then insert."
- "This is an internal endpoint, nothing retries internal calls."
- "Adding idempotency keys is over-engineering for this feature."
- "The payment provider probably handles duplicates on their side."

---

## Why It Works

1. **It reframes "retry" as a property of the network, not the client.** The assistant's default mental model is one caller making one deliberate call. Stating that load balancers and meshes retry removes the "the client won't do that" escape hatch — the client doesn't get a vote.
2. **It forbids the specific broken implementation.** Left alone, an assistant that does add duplicate detection writes `SELECT`-then-`INSERT`, which fails under concurrent retries — exactly the situation it's meant to handle. Naming the unique-constraint pattern closes that trap.
3. **It defines correct replay behavior.** Returning an error on duplicates just moves the bug: the retrying client sees a 409 and can't tell whether the charge happened. Returning the original result makes retries genuinely safe.

## Origin

A subscription service shipped a renewal endpoint that charged the card and then wrote the invoice. Under a brief payment-provider slowdown, gateway timeouts triggered automatic retries, and a few hundred customers were charged two to four times in one evening. The remediation — refunds, support backlog, and retrofitting idempotency keys across nine endpoints — took longer than the original feature did.
