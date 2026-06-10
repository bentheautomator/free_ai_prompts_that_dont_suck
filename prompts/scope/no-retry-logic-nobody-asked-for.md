---
title: No Retry Logic Nobody Asked For
slug: no-retry-logic-nobody-asked-for
category: scope
tags: [universal, scope, over-engineering]
works_with: all
severity: high
one_liner: "AI wrapping simple calls in retries and backoff nobody requested"
---

# No Retry Logic Nobody Asked For

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from wrapping network and I/O calls in retry loops, backoff, and circuit breakers on its own initiative.

**[Copy-paste ready version](../../install/no-retry-logic-nobody-asked-for.md)** — just the instruction block, no explanation.

## The Problem

Asked to add a single API call, the AI delivers the call inside a three-attempt retry loop with exponential backoff, jitter, and a comment about transient failures. Sometimes a timeout decorator joins it; in ambitious moods, a small circuit breaker. The request mentioned none of this. The AI added it because "network calls fail" and resilience boilerplate is what production-grade code looks like in its training data.

Retries are not a safety blanket; they're a correctness decision about idempotency. Retrying a `POST` that timed out after the server processed it means doing the thing twice — charging twice, emailing twice, creating two records. The AI doesn't know whether the endpoint is idempotent, so it's gambling on the user's behalf. Even on safe operations, uncoordinated retries multiply load exactly when the downstream service is struggling (three attempts per caller turns a brownout into a stampede), and they stack: when the caller's caller also retries, three times three is nine.

Real systems put retry policy in one deliberate place — a client wrapper, a service mesh, a job queue — with idempotency keys where needed. Freelance retry loops scattered by an AI answer to no policy at all.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No Retry Logic Nobody Asked For

Make the call once and let failures propagate. NEVER add retry loops, backoff, timeouts-with-retry, or circuit breakers unless the request asks for them.

The core problem: a retry is a bet that the operation is idempotent and that repeating it under failure is safe, which is a system-design decision you don't have the context to make unilaterally.

- Write the call the request asked for, once, with errors propagating to the caller
- No retry loops or backoff around network, database, or filesystem operations on your own initiative
- Never retry non-idempotent operations (POSTs, inserts, sends, charges) under any circumstances without explicit instruction and an idempotency mechanism
- Do not add retry parameters or wrappers "off by default"; dead resilience machinery is still scope creep
- Check whether the project already has a retry layer (HTTP client config, job queue, service mesh) before assuming none exists; duplicating it stacks multiplicatively
- If you believe a call genuinely needs resilience, say which failure you expect and ask: "Should this retry on timeout? Note the endpoint must be idempotent for that to be safe." That sentence is the entire appropriate contribution

**Red flags that you're about to violate this:**
- "Network calls can fail, so I'll add a retry loop..."
- "Exponential backoff is standard practice for external APIs..."
- "Three attempts with jitter makes this production-ready..."
- "I'll wrap this in a timeout and retry to be safe..."
- "A small circuit breaker will protect the downstream service..."
- "Retries are harmless for read operations, and this is probably a read..."

---

## Why It Works

1. **It converts "resilience" into "idempotency bet."** The AI frames retries as pure safety; renaming them as a wager on repeat-safety it cannot verify puts the decision where it belongs, with someone who can.

2. **It surfaces the stacking problem.** Retry layers multiply; requiring a check for existing policy attacks the most common real-world failure, where the AI's loop sits inside two others.

3. **It bans the dormant version.** "Off by default" retry machinery feels like a compromise; naming it as creep prevents the AI from shipping the complexity while technically not retrying.

4. **It scripts the correct contribution.** The provided question, including the idempotency caveat, lets the AI demonstrate its resilience knowledge in one sentence instead of in code.

## Origin

An assistant added an order-submission call with a default three-attempt retry "for reliability." Under a payment-gateway slowdown, requests timed out after the gateway had accepted them, retries resubmitted, and a few hundred customers were charged two or three times during one evening. Refunds, chargeback fees, and a week of support backlog followed. The ticket had said: "call the submit endpoint when the user clicks place order." It did not say "up to three times."
