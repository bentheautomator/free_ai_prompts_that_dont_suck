---
title: Treat Every Queue as At-Least-Once Delivery
slug: treat-every-queue-as-at-least-once-delivery
category: backend
tags: [universal, backend, queues]
works_with: all
severity: critical
one_liner: "Stops duplicate queue deliveries from double-charging and double-sending"
---

# Treat Every Queue as At-Least-Once Delivery

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents consumers built on the exactly-once fantasy from executing side effects twice when the broker redelivers.

**[Copy-paste ready version](../../install/treat-every-queue-as-at-least-once-delivery.md)** — just the instruction block, no explanation.

## The Problem

AI assistants write queue consumers as if each message arrives exactly once: receive, process, done. No real broker promises that. SQS, RabbitMQ, Kafka, Pub/Sub — under the hood they all guarantee at-least-once, and the "least" is doing heavy lifting. A consumer that crashes after processing but before acking gets the message again. A visibility timeout that expires while processing is still running hands the message to another worker *while the first is still working on it*. Network partitions, rebalances, and broker failovers all mint duplicates.

The consequence depends on the side effect. `charge_customer(msg)` runs twice and a customer is double-charged. `send_email(msg)` runs twice and you look broken. `decrement_inventory(msg)` runs twice and you oversell. The duplicate doesn't announce itself — it's the same payload, same fields, often seconds apart, executed by a consumer that has no concept of "have I seen this before?"

Assistants build the exactly-once fantasy because dev delivers it: one broker node, no crashes, no timeouts, every message arriving exactly once for weeks. Even brokers' own "exactly-once" features (Kafka EOS, SQS FIFO dedup) cover narrow windows and stop at the broker's edge — they do not make your database write plus your Stripe call atomic. The consumer has to own duplicate-safety.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Treat Every Queue as At-Least-Once Delivery

ALWAYS write queue and stream consumers assuming every message can be delivered two or more times, including concurrently to different workers. No broker setting exempts you: crash-before-ack, visibility-timeout expiry, and rebalances all produce duplicates, so duplicate-safety lives in the consumer.

- Give every message a stable unique ID at the producer (entity ID + operation, or a UUID minted once). Random IDs minted at consume time defeat deduplication by definition.
- Make the handler idempotent around that ID: record processed IDs in a store with a uniqueness guarantee (unique index, `INSERT ... ON CONFLICT DO NOTHING`, `SETNX`) and check-or-claim *atomically* before executing side effects. A read-then-write check has a race window exactly when two workers hold the same message.
- Where possible, make the operation naturally idempotent instead of tracking IDs: `SET status = 'shipped'` survives duplicates; `counter = counter + 1` does not.
- Pass the message ID through to downstream effects as an idempotency key (payment APIs, email providers) so retries dedupe end to end.
- Ack only after the work is durably complete. Acking first converts "duplicate" into "lost," which is worse.
- Size the visibility timeout/ack deadline above your worst-case processing time, or extend it via heartbeat — otherwise the broker creates concurrent duplicates on purpose.

**Red flags that you're about to violate this:**
- "The queue is configured for exactly-once delivery."
- "We've never seen a duplicate in this queue."
- "FIFO queues dedupe, so the handler doesn't need to."
- "I'll check if it's processed, then process it." (Not atomically? That's the race.)
- "Processing is fast, the visibility timeout won't expire."
- "Adding idempotency keys is over-engineering for an internal queue."

---

## Why It Works

1. **It replaces a false guarantee with the real one.** The assistant defers to "the broker handles it"; naming crash-before-ack and visibility expiry as duplicate factories removes the deferral.
2. **It requires atomic claim, not check-then-act.** Duplicates frequently arrive *concurrently* (timeout expiry hands the message to a second worker mid-flight), so only an atomic uniqueness guarantee actually dedupes. This is the detail naive implementations get wrong.
3. **It extends the key downstream.** Local dedup plus a non-idempotent Stripe call still double-charges when your own process retries; threading the ID through closes the full path.
4. **It fixes the ack ordering.** "Ack early so we don't reprocess" is the instinctive wrong move; the rule pins ack-after-durable-work and accepts duplicates as the survivable failure.

## Origin

A marketplace's payout consumer processed a message in eighty seconds against a sixty-second visibility timeout. The broker, working as documented, redelivered to a second worker at second sixty-one; both completed, and a seller was paid twice. It had run flawlessly for five months — payouts had simply never been slow before. The fix was an atomic claim on the payout ID and a visibility heartbeat; the clawback emails were less mechanical.
