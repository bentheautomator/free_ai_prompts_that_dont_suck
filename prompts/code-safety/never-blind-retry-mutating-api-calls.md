---
title: Never Blind-Retry Mutating API Calls
slug: never-blind-retry-mutating-api-calls
category: code-safety
tags: [universal, api]
works_with: all
severity: critical
one_liner: "AI retrying failed requests that may have succeeded, causing double charges"
---

# Never Blind-Retry Mutating API Calls

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from re-sending non-idempotent requests whose first attempt may have actually gone through.

**[Copy-paste ready version](../../install/never-blind-retry-mutating-api-calls.md)** — just the instruction block, no explanation.

## The Problem

A payment request times out, and the AI retries it. Reasonable — except a timeout doesn't mean the request failed. It means the *response* never arrived. The charge may have landed; the retry charges the customer twice. The same logic double-sends emails, creates duplicate orders, posts the same webhook twice, and re-runs "create" operations into duplicate-key chaos. When the AI then wraps the call in a retry loop with three attempts — its favorite resilience pattern — one flaky network blip becomes three customer charges.

The blind spot is specific: AI assistants treat "request failed" and "operation didn't happen" as the same fact, and they are not. For GET requests the conflation is harmless, which is exactly why the habit forms. For POST-a-payment, POST-an-email, POST-an-order, the gap between those two facts is where every duplicate side effect lives. Mature APIs solve this with idempotency keys — a client-supplied token that makes retries safe — and the AI almost never uses them unless told to, because the happy path works fine without.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Blind-Retry Mutating API Calls

NEVER retry a failed mutating request — payment, send, create, post — without first determining whether the original attempt actually went through. A timeout or connection error means the *response* was lost, not that the operation didn't happen.

The core problem: "the request failed" and "the operation didn't happen" are different facts. Retrying on the first as if it implied the second is how customers get double-charged and emails go out twice.

- Classify before adding any retry logic: is this call idempotent (safe to repeat: GET, PUT-to-same-state, DELETE-by-ID) or non-idempotent (each call acts again: charges, sends, creates)? Retries are only automatic for the first class.
- For non-idempotent calls, use idempotency keys when the API supports them (most payment and messaging APIs do): generate the key once per logical operation, reuse it across retries. With a key, retry freely; without one, don't.
- No key support? Then a failure means: query first. Look the operation up (was the order created? does the charge exist?) before re-attempting. Write this check into any retry logic you author.
- Distinguish error types: a 400 means the request was rejected (retry of the same payload is pointless); a timeout/5xx/connection-reset means outcome unknown (retry is dangerous without a key or a check).
- Never wrap non-idempotent calls in generic retry decorators, queue redelivery, or `for attempt in range(3)` loops. That's a duplicate-side-effect generator with extra steps.
- When writing scripts that resume after failure, make resumption check completed work (processed-ID log) rather than re-running from the top.

**Red flags that you're about to violate this:**
- "It timed out, so I'll just send it again..."
- "I'll add a retry decorator around the API client for robustness..."
- "The error means it didn't work, so retrying is safe..."
- "Three attempts with backoff is standard practice..."
- "If it duplicates, the API probably dedupes on its end..."

---

## Why It Works

1. **It splits the conflated facts.** "Response lost ≠ operation didn't happen" is the precise distinction the AI lacks; once stated, the danger of retrying a timeout becomes derivable rather than counterintuitive.

2. **It gates retries on a classification step.** Forcing an idempotent/non-idempotent sort before any retry logic means the dangerous calls get identified at design time, not discovered at incident time.

3. **It legitimizes retries through keys.** The rule doesn't ban resilience — it routes it through idempotency keys and check-then-retry, so the AI keeps its robustness instinct but loses the duplicate side effects.

## Origin

An assistant added a standard three-retries-with-backoff wrapper around a checkout service's payment client to "handle transient failures." During a degraded-network incident, payment requests were succeeding slowly — past the timeout. The wrapper retried each one up to three times, and a measurable slice of that afternoon's customers were charged two or three times for one order. The payment API had supported idempotency keys all along; the wrapper just hadn't sent one.
