---
title: Freeze Webhook Payload Contracts
slug: freeze-webhook-payload-contracts
category: api-design
tags: [universal, apis, compatibility]
works_with: all
severity: critical
one_liner: "Stops restructuring webhook payloads subscribers parse and cannot re-request"
---

# Freeze Webhook Payload Contracts

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from changing the shape, fields, or event names of webhooks that external subscribers already parse.

**[Copy-paste ready version](../../install/freeze-webhook-payload-contracts.md)** — just the instruction block, no explanation.

## The Problem

Webhooks are the contract with the least forgiveness. A REST consumer that breaks can at least retry against the same data; a webhook subscriber that fails to parse a payload has *lost the event* unless someone built replay. So when an AI assistant reworks the events module — renames `order.completed` to `order.finished` for consistency with new events, moves payload fields under a `data` key to match a cleaner envelope, or changes `event_type` to `type` — subscribers don't get errors they can handle. They get deliveries their handlers ignore or crash on, and the business event evaporates.

The damage is invisible from the sender's side. Delivery succeeded: the subscriber returned 200 before parsing, as most do. Dashboards show webhooks flowing. Meanwhile a partner's fulfillment system is dropping every order event on the floor because the switch statement matches `order.completed` and nothing else.

AI assistants restructure webhook code more casually than API endpoints because nothing in the repo *consumes* the payload — there's no internal caller to update, no test that simulates the partner's parser, nothing to break locally. The payload builder looks like internal code. It's the most external code in the repository.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Freeze Webhook Payload Contracts

NEVER change the structure, field names, event type strings, or envelope of an existing webhook payload. Webhook subscribers are external parsers you cannot see, and unlike API callers they cannot retry or re-request: an event their handler can't parse is an event lost forever.

- Frozen elements include: the event name/type string (`order.completed`), every payload key and its type, the envelope structure (`data` wrapper, `meta`, top-level vs. nested), ID and timestamp formats, and how absence is expressed (null vs. omitted).
- Subscribers route on the event type string with exact matching. Renaming an event, even trivially, means their switch statement silently falls through — delivery still returns 200, so no alarm fires anywhere.
- Evolve additively only: add new optional fields to existing payloads, or introduce entirely new event types alongside old ones. To restructure, publish a new event version (`order.completed.v2`) and keep emitting v1 until subscribers migrate.
- Webhook payload builders look like internal code because nothing in the repo reads their output. That is exactly backwards: zero internal consumers means 100% of consumers are external.
- If the user explicitly asks to change a webhook's shape, state that all current subscribers will mis-parse or drop the events with no error visible on either side, and recommend the versioned-event path with a migration window.

**Red flags that you're about to violate this:**
- "I'll rename the event to match the naming convention of the new events."
- "Wrapping the payload in a data envelope makes all our webhooks consistent."
- "Nothing in this codebase parses these payloads, so the shape is free to change."
- "Subscribers get the events over HTTP — they'll see the new fields immediately."
- "It's our outbound data; we control the format."

---

## Why It Works

1. **It names the no-retry property**, the thing that makes webhooks stricter than APIs: the AI's background assumption that consumers can adapt and re-fetch is false here, and saying so raises the stakes correctly.
2. **It flips the "no internal consumers" signal** from safe-to-change to maximally-external — the exact inference error that makes webhook code the most casually refactored serialization boundary.
3. **It identifies event-type strings as routing keys**, not labels, so renames register as breaking the subscriber's dispatch rather than improving taxonomy.
4. **It provides the versioned-event pattern**, giving the restructuring impulse a destination that doesn't require touching v1.

## Origin

While unifying an events module, an assistant standardized all webhook payloads into a `{type, data, timestamp}` envelope; previously each event's fields had been top-level. Every subscriber parsing `payload.invoice_id` began reading undefined, and all of them returned 200 anyway. For nine days both sides' dashboards were green while a billing partner's automation processed nothing, and the events from those nine days had no replay mechanism — they were reconstructed by hand from database history.
