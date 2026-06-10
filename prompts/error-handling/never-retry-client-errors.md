---
title: Never Retry Client Errors
slug: never-retry-client-errors
category: error-handling
tags: [universal, errors, retries]
works_with: all
severity: high
one_liner: "AI retrying 400s and auth failures as if they were transient outages"
---

# Never Retry Client Errors

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents retry loops from hammering an API with requests that are guaranteed to fail every time.

**[Copy-paste ready version](../../install/never-retry-client-errors.md)** — just the instruction block, no explanation.

## The Problem

Asked to "add retries" to an HTTP call, the AI wraps the whole thing: `for attempt in range(5): try: resp = call(); break; except Exception: sleep(2 ** attempt)`. Now a 503 gets retried — good — but so does a 400. A 400 means the request itself is malformed. It will be malformed on attempt two, attempt three, and attempt five, because nothing about the request changed. The retry loop converts a one-millisecond failure into a thirty-second failure with five times the load, and then fails anyway.

The deeper damage is diagnostic. A 401 retried five times looks like flakiness in the logs when it's actually an expired credential. A 422 retried with backoff delays the real signal — "your payload is wrong" — behind a wall of identical attempts. And a 429 retried *without honoring Retry-After* is the client actively making its own rate-limiting worse.

Assistants do this because "retry on failure" is the instruction and status-code taxonomy is the part that requires judgment. Catching everything and retrying everything is the version that needs no judgment, so it's the version you get.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Retry Client Errors

Retry ONLY errors that can plausibly succeed on a second attempt without anything changing. NEVER retry an error caused by the request itself.

Retrying a deterministic failure doesn't add resilience — it multiplies load, delays the real error, and disguises a bug as flakiness.

- Retryable: network timeouts, connection resets, HTTP 502/503/504, and 429 (only while honoring the `Retry-After` header if present)
- Not retryable: HTTP 400, 401, 403, 404, 405, 409, 422 — validation failures, bad credentials, missing resources, and conflicts will fail identically every attempt; fail immediately and surface the response body
- The same taxonomy applies outside HTTP: retry a database deadlock or connection drop; never retry a constraint violation, a syntax error, or a serialization failure of your own payload
- Write the retry condition as an explicit allowlist of retryable statuses/exception types, not `except Exception` around the whole call
- A 401/403 must propagate loudly — it usually means an expired or misconfigured credential, and every retry delays that discovery
- If a library's built-in retry is in use (urllib3 `Retry`, axios-retry), configure its `status_forcelist`/condition explicitly; defaults are not a decision

**Red flags that you're about to violate this:**
- "I'll retry on any exception to make it resilient..."
- "Five attempts with backoff should handle most failures..."
- "A 400 might be transient on their end..."
- "Retrying auth errors covers token race conditions..."
- "It's simpler to retry everything than to classify errors..."

---

## Why It Works

1. **It defines retryability by mechanism, not by category list alone.** "Can succeed without anything changing" is a test the model can apply to errors not on the list, which prevents the rule from collapsing the first time it meets an unlisted status code.

2. **It forces an allowlist structure.** `except Exception` plus retry is the natural shape of lazy resilience; requiring an explicit list of retryable conditions makes the lazy shape syntactically impossible.

3. **It attacks the "more retries = more robust" prior.** Stating the actual cost — multiplied load, delayed diagnosis, bug disguised as flakiness — replaces the vague virtue the model assigns to retrying.

4. **It singles out 401/403 as urgent signals.** Credential failures are the most expensive errors to retry quietly; naming them prevents the model from lumping them in with "server might be having a moment."

## Origin

An assistant added "robust retry logic" to a billing integration: five attempts, exponential backoff, on any non-200. A schema change upstream started returning 422 for every request. Instead of one clear failure, the integration produced five identical attempts per invoice across thousands of invoices, tripping the vendor's rate limiter and getting the API key temporarily banned — which then *did* produce retryable errors, burying the original 422 three layers deep in the logs. Diagnosis took most of a day; the actual fix was renaming one field.
