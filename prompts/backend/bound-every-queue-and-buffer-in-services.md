---
title: Bound Every Queue and Buffer in Services
slug: bound-every-queue-and-buffer-in-services
category: backend
tags: [universal, backend, queues]
works_with: all
severity: high
one_liner: "Stops unbounded in-process queues from eating memory until OOM"
---

# Bound Every Queue and Buffer in Services

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents in-process queues, channels, and buffers with no size limit from growing until the process is OOM-killed.

**[Copy-paste ready version](../../install/bound-every-queue-and-buffer-in-services.md)** — just the instruction block, no explanation.

## The Problem

When an AI assistant needs to decouple a producer from a consumer inside a service — buffer log events, batch writes, smooth out a bursty workload — it reaches for the unbounded version every time: `queue.Queue()` with no maxsize, an array used as a backlog with `push` and a worker draining it, an unbuffered Go channel swapped for `make(chan T, 100000)` when the obvious deadlock appears. The code is short and works perfectly in dev, where the producer is one curl command and the consumer is never slow.

In production, queues exist precisely because producers sometimes outrun consumers. An unbounded queue converts that imbalance into memory growth: the consumer slows down (slow downstream, GC pressure, a deploy), the queue absorbs the difference, memory climbs, GC pressure makes the consumer slower still, and the process dies with the entire backlog in RAM. Everything in the queue is lost, and the restart begins filling the same queue again.

The deeper miss is backpressure. A bounded queue forces a decision — block the producer, shed load, or spill to durable storage — and the assistant avoids that decision by leaving the bound off. Unbounded isn't a design; it's a deferred outage.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Bound Every Queue and Buffer in Services

NEVER create an unbounded in-process queue, channel, or backlog buffer in a long-running service. An unbounded queue is a memory leak with a business justification: any sustained gap between producer and consumer rates grows it until the process dies, losing everything it held.

- Give every queue an explicit capacity: `queue.Queue(maxsize=N)`, a bounded channel, a deque with `maxlen`, a bounded executor work queue. Pick N from real numbers (memory per item × tolerable backlog), not a vibe.
- Decide at design time what happens when the queue is full, and implement exactly one of: block the producer (backpressure), reject the new item with an error the caller sees, or drop with a counter/metric. Silent unbounded growth is not on the list.
- Arrays and maps used as backlogs count: a `pendingEvents.push(...)` with a periodic flush is a queue, and it needs a cap and an overflow policy too.
- If losing queued items on crash is unacceptable, the buffer belongs in a durable broker or database, not process memory. A big in-memory queue is the worst of both: unbounded risk and zero durability.
- Bound thread pools and their submission queues together — an executor with a bounded pool but unbounded task queue still grows without limit.
- Emit queue depth as a metric. A queue you cannot observe will surprise you.

**Red flags that you're about to violate this:**
- "The consumer is fast, the queue will stay near empty."
- "I'll make the channel buffer huge so the producer never blocks."
- "Adding a maxsize means handling the full case, which complicates this."
- "It's just a temporary buffer for bursts."
- "We can add a limit later if memory becomes a problem."
- "Dropping items feels wrong, so I'll keep everything."

---

## Why It Works

1. **It names the false comfort.** "The consumer keeps up" is true in dev and on the median production day; queues earn their keep on the bad day. Stating that the queue grows on *any sustained imbalance* defeats the average-case reasoning.
2. **It forces the full-queue decision at design time.** The assistant leaves bounds off to avoid choosing between blocking, rejecting, and dropping. Making that choice mandatory removes the escape hatch — unbounded growth is explicitly excluded from the menu.
3. **It widens the definition of "queue".** Assistants apply queue discipline to things named Queue and exempt the array-plus-flush-loop pattern. Counting backlogs-by-any-name closes that gap.
4. **It separates buffering from durability.** "Keep everything in memory so nothing is lost" loses everything at once on OOM. Naming that paradox redirects truly-must-not-lose data to durable storage.

## Origin

An ingestion service buffered analytics events in an in-memory list, flushed to a warehouse every five seconds. A warehouse slowdown during a traffic spike turned five-second flushes into ninety-second ones; the list absorbed the gap for eleven minutes before the pod was OOM-killed with roughly two million events on board. Kubernetes restarted it into the same spike, and the crash loop repeated until the warehouse recovered. The fix was a bounded buffer that shed to disk, plus a depth metric that would have shown the problem nine minutes before the first kill.
