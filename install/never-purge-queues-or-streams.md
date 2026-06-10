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
