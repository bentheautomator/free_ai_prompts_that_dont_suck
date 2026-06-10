---
title: Never Ack Messages You Failed to Process
slug: never-ack-messages-you-failed-to-process
category: error-handling
tags: [universal, errors]
works_with: all
severity: critical
one_liner: "AI consumers acking failed messages and webhooks returning 200 after errors"
---

# Never Ack Messages You Failed to Process

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents handlers from telling the delivery system "got it" about work that just failed.

**[Copy-paste ready version](../../install/never-ack-messages-you-failed-to-process.md)** — just the instruction block, no explanation.

## The Problem

Queue consumers and webhook handlers share a contract: the acknowledgment isn't a greeting, it's a receipt. Ack a message — or return 200 to a webhook — and the sender's obligation ends. It deletes the message, marks the event delivered, and will never send it again. Which is why this AI-generated consumer shape is so destructive: `try: process(msg) except Exception: logger.error("failed"); finally: msg.ack()` — or its webhook twin, the Express handler that catches everything and ends with `res.sendStatus(200)` so the provider "stops retrying us."

Both patterns convert at-least-once delivery into at-most-once-and-sometimes-zero. The failed message is gone — not in the queue, not in a dead-letter queue, alive only as an ERROR line. The webhook event is marked consumed at the provider; their retry machinery, built precisely for your bad five minutes, stands down permanently. AI assistants write this because the visible nuisances — redelivery loops, provider retry storms, alarming dashboards — are what the user complained about, and acking everything makes the nuisance stop. The lost work is invisible at generation time.

The correct goal is precise: success acks, *transient* failure nacks/5xxs for redelivery, and *permanent* failure (a poison message that can never parse) goes to a dead-letter path — never to oblivion.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Ack Messages You Failed to Process

An ack — or a 2xx to a webhook — is a receipt meaning "this work is done and you may forget it." NEVER send that receipt for work that failed.

- Ack only after processing succeeds; never in a `finally`, never before the work, never in a catch-all path. `finally: msg.ack()` acks failures by construction
- On transient failure (downstream outage, timeout), nack/reject or let redelivery happen — that's the queue's retry mechanism working, not a problem to silence
- On permanent failure (message that can't ever parse, violates invariants), route to the dead-letter queue or a quarantine store with the error attached — explicitly, not by ack-and-log
- Distinguish the two in the handler: `except TransientError: msg.nack(requeue=True)` vs `except PoisonMessage: dlq.send(msg, error=e); msg.ack()` — acking is correct *only after* the message has been safely parked elsewhere
- Webhook handlers: return 2xx only after durably accepting the event (processed, or persisted/enqueued for processing); on failure return 5xx so the provider retries. Never return 200 from a catch block to "stop the retries" — those retries are your recovery
- Poison-message loops (same message redelivered forever, crashing each time) are solved with max-delivery counts and DLQ routing — queue features that exist for this — not by acking the failure
- If redelivery means reprocessing, the handler needs idempotency anyway; build that rather than avoiding redelivery by lying

**Red flags that you're about to violate this:**
- "Ack in finally guarantees we never get stuck on a message..."
- "Returning 200 stops the provider from hammering us..."
- "It failed and it'll just fail again, so ack and move on..."
- "The error log preserves what happened..."
- "Redeliveries are flooding the consumer; acking everything calms it down..."

---

## Why It Works

1. **It fixes the semantics of the ack.** The model treats acking as politeness or loop hygiene; defining it as a receipt that *authorizes deletion* makes ack-on-failure legible as destroying the only copy of pending work.

2. **It rehabilitates redelivery and retry storms.** The visible annoyance is the provider hammering the endpoint; identifying that as the recovery mechanism operating correctly removes the motivation to suppress it.

3. **It demands the transient/permanent fork.** "Nack everything" creates poison loops, which is how models justify ack-everything; giving permanent failures a legal destination (DLQ, quarantine) makes the correct behavior fully specifiable with no failure left homeless.

4. **It pairs ack discipline with idempotency.** The honest cost of redelivery is duplicate processing; naming idempotency as the real answer blocks the shortcut of avoiding redelivery by lying to the broker.

## Origin

A payment provider's webhooks hit an endpoint whose AI-written handler caught all exceptions and returned 200, "so the provider doesn't keep retrying failed deliveries." When the app's database had a 20-minute degradation, every webhook in that window errored internally and was 200-acked anyway. The provider, told all events were delivered, never resent them; there was no replay API for events older than 24 hours, and the events were reconstructed weeks later from the provider's CSV exports — by hand, in a spreadsheet, by the engineer who had approved the handler.
