---
title: Dedupe Webhook Deliveries by Event ID
slug: dedupe-webhook-deliveries-by-event-id
category: backend
tags: [universal, backend, webhooks]
works_with: all
severity: critical
one_liner: "Stops duplicate webhook deliveries from running side effects twice"
---

# Dedupe Webhook Deliveries by Event ID

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents webhook handlers that execute side effects once per delivery instead of once per event, when providers deliver at-least-once.

**[Copy-paste ready version](../../install/dedupe-webhook-deliveries-by-event-id.md)** — just the instruction block, no explanation.

## The Problem

Every major webhook provider documents the same thing: delivery is at-least-once. If your endpoint is slow, returns a 5xx, or the provider's dispatcher hiccups, the same event will be delivered again — sometimes seconds later, sometimes hours later, sometimes concurrently. The event object even ships with a unique ID specifically so receivers can deduplicate.

AI assistants write webhook handlers that ignore all of this. Ask for "a handler for the `payment.succeeded` webhook" and you get: parse body, mark order paid, send confirmation email, return 200. Run that against real delivery semantics and a redelivered event sends the customer two confirmation emails; with a `subscription.created` event it provisions two licenses; with a credit event it grants the credit twice. The handler is correct per delivery and wrong per event, and the difference never shows up in dev because the test harness delivers everything exactly once.

The provider already gave you the dedup key. The failure is purely on the receiving end: nobody recorded which event IDs have been processed.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Dedupe Webhook Deliveries by Event ID

ALWAYS treat webhook delivery as at-least-once and deduplicate by the provider's event ID before running side effects. Every serious webhook provider redelivers on timeout, error, or internal retry; a handler that acts once per delivery will act twice per event.

- Extract the provider's unique event ID (e.g. `event.id`, a delivery GUID header) and record it in durable storage with a unique constraint as part of processing. If the insert conflicts, the event was already handled: return 200 and do nothing.
- Make the dedup check atomic with the work, or at minimum insert-first: `INSERT ... ON CONFLICT DO NOTHING` and only proceed if the row was inserted. A read-then-act check loses to two deliveries arriving concurrently, which providers genuinely do.
- Return success for duplicates. Returning an error tells the provider the delivery failed and earns you another redelivery of the event you just declined.
- Dedup storage must be shared and durable: a database table or shared store, never an in-process `Set` (wiped on restart, invisible to other replicas).
- If the provider sends no event ID, derive a deterministic one from stable payload fields and document the choice.
- Keep processed-ID rows at least as long as the provider's maximum retry window (check the docs; days, not minutes), then prune by timestamp.

**Red flags that you're about to violate this:**
- "The provider sends each event once, that's the whole point of webhooks."
- "Duplicates would only happen if we error, and we won't error."
- "I'll keep a set of seen IDs in memory."
- "Checking for an existing order status first is enough deduplication."
- "Returning 409 on duplicates seems more semantically correct."
- "Dedup is something we can add when it becomes a problem."

---

## Why It Works

1. **It replaces the assistant's delivery model with the documented one.** The default mental model is "one event, one HTTP call." Stating at-least-once as a fact about all serious providers — including concurrent redelivery — removes the premise the buggy handler is built on.
2. **It specifies the atomic insert-first pattern.** An assistant told merely to "handle duplicates" writes a status check before the work, which fails exactly when two deliveries race. Naming `INSERT ... ON CONFLICT` as the gate closes the obvious wrong implementation.
3. **It defines the duplicate response.** Returning an error for a duplicate feels right and causes more redeliveries; making "200 and do nothing" the explicit contract breaks that loop.
4. **It disqualifies in-memory dedup by mechanism.** Restarts and replicas are named outright, so the convenient `Set` never looks viable.

## Origin

A billing integration handled `invoice.paid` webhooks by crediting the customer's account and emailing a receipt. During a provider-side dispatcher incident, roughly a third of one evening's events were delivered two or three times; the handler credited accounts on every delivery. Reconciling the over-credits took the finance team most of a week, and the fix — one event-ID table with a unique constraint — was four lines of code the docs had recommended all along.
