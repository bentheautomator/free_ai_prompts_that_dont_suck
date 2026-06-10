---
title: Never Purge Queues or Streams to Unstick Them
slug: never-purge-queues-or-streams
category: code-safety
tags: [universal, production, data]
works_with: all
severity: critical
one_liner: "AI purging message queues full of unprocessed work to clear a backlog"
---

# Never Purge Queues or Streams to Unstick Them

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from deleting in-flight messages — pending jobs, unprocessed events, queued work — to make a backlog or error go away.

**[Copy-paste ready version](../../install/never-purge-queues-or-streams.md)** — just the instruction block, no explanation.

## The Problem

A queue has 40,000 messages backed up and consumers are erroring, so the AI purges the queue. Errors stop immediately — there's nothing left to err on. Those 40,000 messages were orders awaiting fulfillment, emails awaiting delivery, events awaiting processing. A queue purge is a bulk delete of work the system promised to do, and most queue systems make it permanent and instant: SQS `purge-queue`, RabbitMQ queue purge, deleting a Kafka topic, flushing a Redis-backed job queue. No trash, no undo, no "are you sure" once the API call lands.

The AI reaches for purging because backlogs and poison messages *present* as the queue's fault: queue full, consumers crashing, depth alarm firing. Emptying the queue resolves every symptom. But messages in a queue are data in transit — often the only copy of "this happened and hasn't been handled yet." Unlike a database, nobody thinks to back up a queue, because messages are supposed to be ephemeral. They're ephemeral on the way *out*, after processing. Deleting them on the way in is dropping signed-for packages into the sea.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Purge Queues or Streams to Unstick Them

NEVER purge a message queue, delete a topic, or flush a job queue to clear a backlog or stop consumer errors. Queued messages are unprocessed work — orders, events, emails the system has accepted but not yet handled — and purging is an instant, irreversible bulk delete of all of it.

The core problem: backlogs and crashing consumers make the queue *look* like the problem, and emptying it resolves every symptom by destroying the work. The messages weren't the bug; they were the victims of it.

- Diagnose the consumer, not the queue. A backlog means processing stopped or slowed; fix the consumer, scale it, or fix the poison message — the backlog then drains itself.
- For poison messages (one bad message crashing consumers in a loop): move that message to a dead-letter queue or sideline it for inspection. One message is the problem; don't delete forty thousand to get it.
- Before any destructive queue operation the user explicitly approves: report the current depth and what the messages represent ("38,000 pending order-confirmation events"), and whether they can be regenerated upstream. Usually they can't.
- If messages truly must be removed, drain to storage first: consume the queue to a file or bucket so the contents exist somewhere before the queue is empty. An archived backlog can be replayed; a purged one cannot.
- These commands are in the never-without-explicit-instruction class: `purge-queue`, queue/topic deletion, `FLUSHALL`/`FLUSHDB` on job-queue stores, deleting consumer groups or resetting offsets (silently skips unprocessed messages — same loss, sneakier shape).
- Test environments get a lighter touch only when you've verified nothing real feeds into them.

**Red flags that you're about to violate this:**
- "The queue is jammed — purging it will get things moving..."
- "These messages are causing the crashes, clear them out..."
- "It's mostly stale events at this point anyway..."
- "I'll reset the consumer offset to latest and skip the backlog..."
- "Queues are ephemeral by design, this is what purge is for..."

---

## Why It Works

1. **It relabels messages as accepted-but-unfinished work.** The AI's "queues are ephemeral" model justifies deletion; reframing each message as a promise the system already made ("this order exists and hasn't been fulfilled") makes purging legible as breaking 40,000 promises at once.

2. **It isolates the poison-message case.** Most justified-feeling purges are one bad message wearing a 40,000-message disguise. Prescribing dead-lettering for exactly that case removes the main legitimate-sounding trigger.

3. **It offers drain-to-storage as the pressure valve.** When removal is genuinely needed, archiving first converts an irreversible purge into a reversible one — preserving the AI's ability to act without preserving the data loss.

## Origin

Consumers on an order-events queue were crash-looping, and an assistant resolved the incident by purging the queue — depth 31,000 — noting that the "corrupted messages" were now cleared. One message was malformed. The other 30,999 were a holiday weekend's order confirmations, which now would never send, and the upstream system had no replay capability. Sidelining the single bad message would have taken one command and lost nothing.
