---
title: Never Assume Message Order
slug: never-assume-message-order
category: concurrency
tags: [universal, concurrency, ordering]
works_with: all
severity: high
one_liner: "Stops handlers that break when events arrive out of order or twice"
---

# Never Assume Message Order

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from writing event and message handlers that only work if messages arrive exactly once, in exactly the order they were sent.

**[Copy-paste ready version](../../install/never-assume-message-order.md)** — just the instruction block, no explanation.

## The Problem

The AI writes a webhook handler that processes `order.created` and then `order.paid`, assuming they arrive in that order, because that's the order they happen in. It processes `user.updated` events by applying each one as the newest, because they're sent newest-last. Then the queue redelivers, a retry reorders, two producer instances interleave, or the network does what networks do, and `paid` arrives before `created`. The handler throws "unknown order," or worse, doesn't throw — it applies a stale `user.updated` over a fresh one and the user's corrected email reverts to the typo'd one, permanently, with no error anywhere.

This is a default failure because the happy-path order is the only order the AI has evidence of. Local testing sends events in sequence from one producer over one connection; everything arrives in order, exactly once, forever, until production. Most real transports — webhooks, SQS standard queues, pub/sub fan-outs, multiple partitions, anything with retries — explicitly do not guarantee global order or single delivery, and the handler's assumptions are never written down anywhere the AI would see them.

Ordered-and-once is a property you build at the receiver, not one you inherit from the wire.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Assume Message Order

ALWAYS write event and message handlers as if messages can arrive out of order, late, and more than once, because on most transports they can and eventually will.

Send order is not arrival order; one delivery is not the guaranteed count. Handlers that encode "this always comes after that" encode a coincidence.

- Make every handler idempotent: processing the same message twice must equal processing it once. Key on a message/event ID, not on "this shouldn't happen."
- For state updates, compare versions or timestamps from the event payload before applying: ignore or park an event older than the state you already hold, instead of last-write-wins on arrival order.
- For events that reference earlier ones (`paid` before `created` arrived), don't crash and don't drop: park and retry, or upsert a placeholder the earlier event will fill in.
- Never use arrival order to infer causality across different keys, partitions, topics, or producers. Order is only ever per-partition/per-key at best; check what your transport actually guarantees before leaning on even that.
- Don't "fix" ordering with sleeps or delayed retries tuned until the happy path wins; that's scheduling a coin flip.
- State machines beat flags: `status: created → paid → shipped` with explicit handling for early arrivals is debuggable; six booleans updated in assumed order are not.

**Red flags that you're about to violate this:**
- "These events are always sent in this order, so they arrive in it."
- "The queue is FIFO." (Check the actual guarantee, including retries and DLQ redrives.)
- "Duplicates would be a bug on the producer side, not my problem."
- "I'll just process whatever's newest, which is whatever arrived last."
- "Out-of-order is so rare it's not worth handling."

---

## Why It Works

1. **It replaces an invisible assumption with a stated contract** — "out of order, late, duplicated" — that the AI can design against, instead of designing against the one trace it has seen.
2. **Idempotency-by-ID and version-compare are mechanical patterns**; once named, the AI applies them reliably, whereas "be robust" produces nothing.
3. **It distinguishes arrival order from event order,** which is the precise confusion behind last-write-wins corruption: the timestamp in the payload outranks the timestamp on the doormat.
4. **It closes the park-or-placeholder gap** for early-arriving dependents, the case where most handlers choose between crashing and silently acking data loss.

## Origin

A billing integration applied subscription webhooks in arrival order. During a provider incident, retried events arrived hours late and out of sequence; a stale `subscription.updated` overwrote dozens of cancellations, and customers who had cancelled kept getting charged. The handler had no errors to show because nothing had failed: every event was processed "successfully," in exactly the order it knocked on the door.
