---
title: Never Blind-Retry Non-Idempotent Operations
slug: never-blind-retry-non-idempotent-operations
category: error-handling
tags: [universal, errors, retries]
works_with: all
severity: critical
one_liner: "AI retrying payments and inserts after timeouts, causing duplicate execution"
---

# Never Blind-Retry Non-Idempotent Operations

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents retry logic from charging the card twice because the first success's response got lost.

**[Copy-paste ready version](../../install/never-blind-retry-non-idempotent-operations.md)** — just the instruction block, no explanation.

## The Problem

A timeout is not a failure. It's an unknown. When `POST /charge` times out, the request may have died en route — or it may have succeeded, with only the *response* lost. Retry logic that treats timeout as "didn't happen" will, some fraction of the time, execute the operation again on top of a success it couldn't see. For idempotent operations (GET, PUT-to-same-state, DELETE) that's harmless. For charges, order creation, inventory decrements, email sends, and plain SQL INSERTs, it's duplication: double charges, double orders, double emails.

AI assistants bolt retry wrappers onto whatever call was flaky, and the wrapper doesn't know what the call *does*. `retry(3)(create_order)` compiles exactly as cleanly as `retry(3)(get_order)`. The training-data idiom "wrap network calls in retries" carries no idempotency check, so the generated code doesn't either. The bug then hides beautifully: it only fires on the timeout-after-success race, so it's rare, unreproducible in dev, and shows up as scattered duplicate records that get blamed on users double-clicking.

The fix isn't "never retry writes" — it's making the write *safe* to retry first, or not retrying it at all.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Blind-Retry Non-Idempotent Operations

Before adding retries to any operation, answer: if this executed twice, would the second execution be harmless? If not, you MUST NOT retry it until you've made it safe — a timeout may mean the first attempt actually succeeded.

A timeout is not "it didn't happen." It's "I don't know what happened." Retrying on top of an invisible success is how duplicates are born.

- Classify before wrapping: reads and idempotent writes (PUT to a fixed state, DELETE by id, upsert-by-key) may retry freely; creates, charges, sends, increments, and appends may not — by default
- To make a write retryable, give it an idempotency key: pass the provider's idempotency header (most payment and messaging APIs support one), or use a client-generated unique key with a uniqueness constraint so replays collide instead of duplicating
- Without an idempotency mechanism, a timed-out non-idempotent call must not be blindly re-sent: surface the ambiguous outcome to the caller, or query the resource first ("did order with this reference get created?") before re-attempting
- Distinguish failure classes: "connection refused before sending" is safe to retry even for writes (the request never arrived); "timeout awaiting response" is the dangerous ambiguity
- Never put a generic retry decorator/interceptor on a client that performs writes without auditing every write endpoint it covers
- Apply the same test to queue redelivery and cron re-runs: anything that may execute twice needs the same idempotency design, not just HTTP calls

**Red flags that you're about to violate this:**
- "I'll wrap this API call in the standard retry helper..."
- "Timeout means it failed, so retrying is safe..."
- "Duplicates are an edge case we can clean up later..."
- "The payment provider probably dedupes on their side..."
- "Three retries on the order endpoint will fix the flakiness..."

---

## Why It Works

1. **It corrects the semantics of timeout.** "Unknown, not failure" is the single conceptual error underneath every double-charge retry bug; fixing the premise fixes the generated code.

2. **The twice-test is local and answerable.** The model can evaluate "what does executing this twice do?" from the call site, without whole-system knowledge — making the rule applicable at exactly the moment the retry wrapper is being typed.

3. **It offers the engineering path, not just a prohibition.** Idempotency keys and check-before-retry give the model a way to satisfy both "be resilient" and "don't duplicate," removing the pressure to quietly pick the first.

4. **It splits failure classes by what the server saw.** Connection-refused vs. response-timeout is the precise line between safe and unsafe write retries; teaching that line prevents both overcaution and overconfidence.

## Origin

A checkout service got an AI-added retry wrapper after a week of intermittent gateway timeouts: three attempts, exponential backoff, applied to the whole payment client. The timeouts were on the response path — the gateway was processing slowly but successfully. For three days, roughly one in two hundred customers was charged two or three times for one order. Refunds, support tickets, and a chargeback fee later, the durable fix was an idempotency key per checkout session: one line in the request, supported by the gateway all along.
