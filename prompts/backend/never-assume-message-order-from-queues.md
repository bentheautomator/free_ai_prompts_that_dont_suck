---
title: Never Assume Message Order From Queues
slug: never-assume-message-order-from-queues
category: backend
tags: [universal, backend, queues]
works_with: all
severity: high
one_liner: "Stops consumers from breaking when the queue delivers messages out of order"
---

# Never Assume Message Order From Queues

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents consumers that silently depend on FIFO delivery from corrupting state the first time messages arrive out of order.

**[Copy-paste ready version](../../install/never-assume-message-order-from-queues.md)** — just the instruction block, no explanation.

## The Problem

Ask an AI assistant to write a consumer that processes `order.created` then `order.paid` then `order.shipped`, and it will write a state machine that assumes the events show up in that order. In dev, they do: one producer, one consumer, one partition, no retries. The code works perfectly, which is exactly the problem.

Production queues do not promise that. SQS standard queues explicitly reorder. Kafka only orders within a partition, and the assistant rarely checks how the partition key is chosen. RabbitMQ reorders the moment a message is nacked and redelivered, or when you add a second consumer. Retries, dead-letter requeues, competing consumers, and multi-AZ brokers all shuffle delivery. The consumer that assumed order now applies `shipped` before `paid`, throws on an "impossible" state, or worse, quietly overwrites newer data with older data.

Assistants default to ordered logic because the event sequence in the spec reads like a story, and code that follows the story is the shortest code that passes the demo. The disorder only appears under load, redelivery, or scale-out — three things dev never has.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Assume Message Order From Queues

NEVER write a queue consumer that depends on messages arriving in the order they were produced. Competing consumers, retries, redeliveries, and multi-partition brokers all reorder messages, so a consumer that assumes sequence will corrupt state in production.

- Make each message self-sufficient: include the entity ID and either a version number, sequence number, or authoritative timestamp from the producer, so the consumer can decide what to do without trusting arrival order.
- Use last-write-wins guarded by version: reject or ignore a message whose version/sequence is older than what is already stored (`UPDATE ... WHERE version < :incoming`). Never blindly apply the latest arrival.
- For genuine state machines, treat out-of-order arrivals as expected input: either park the early message for redelivery, or store it and reconcile when the missing predecessor arrives. Do not throw on "impossible" transitions.
- If strict ordering is truly required, get it from the broker explicitly (FIFO queue with message group ID, Kafka partition keyed by entity ID, single consumer per key) and say so in a comment. Do not get it implicitly from "there's only one consumer right now."
- Remember that redelivery reorders even single-consumer setups: a nacked message goes to the back of the line while newer messages sail past it.

**Red flags that you're about to violate this:**
- "Events are published in order, so they arrive in order."
- "There's only one consumer, so ordering is guaranteed."
- "The paid event always comes after the created event."
- "I'll throw an exception if the state transition is invalid — it can't happen."
- "Kafka is ordered." (Only per partition, only with the right key.)
- "Handling out-of-order events makes the consumer too complicated."

---

## Why It Works

1. **It names the reordering mechanisms.** "Queues can reorder" is abstract; "a nack sends the message to the back of the line while newer ones pass it" gives the assistant a concrete scenario it must code against.
2. **It supplies the version-guard pattern.** Without a stated alternative, "don't assume order" produces hand-wringing comments. With `WHERE version < :incoming`, it produces a correct upsert.
3. **It closes the single-consumer loophole.** "There's only one consumer" is true today and false after the first scaling event. Forcing explicit broker-level ordering makes the assumption visible and reviewable.
4. **It reframes out-of-order as normal input.** Code that treats disorder as an exception path crashes; code that treats it as a routine case reconciles.

## Origin

A logistics platform consumed shipment events with a state machine that hard-errored on invalid transitions. A broker failover redelivered a few thousand messages out of order; `delivered` arrived before `out_for_delivery` for a fraction of shipments, the consumer threw, the messages dead-lettered, and those shipments froze on the tracking page for two days. The fix was a version column and one WHERE clause.
