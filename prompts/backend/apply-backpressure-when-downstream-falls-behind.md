---
title: Apply Backpressure When Downstream Falls Behind
slug: apply-backpressure-when-downstream-falls-behind
category: backend
tags: [universal, backend, reliability]
works_with: all
severity: high
one_liner: "Makes producers slow down instead of burying a struggling consumer"
---

# Apply Backpressure When Downstream Falls Behind

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents producers that publish at full speed regardless of consumer health from turning a slow downstream into a buried one.

**[Copy-paste ready version](../../install/apply-backpressure-when-downstream-falls-behind.md)** — just the instruction block, no explanation.

## The Problem

When an assistant writes the producing side of a pipeline — an API that enqueues jobs, a service that streams events, a batch process that fans work into a queue — it writes fire-and-forget at maximum speed. Publish returns instantly, so as far as the producer can tell, everything is fine. It keeps accepting requests, keeps generating events, keeps shoveling, with zero awareness of whether anything downstream is keeping up.

When the consumer slows down — a bad deploy, a slow dependency, a 10x traffic day — nothing tells the producer to ease off. The queue depth climbs from hundreds to millions. End-to-end latency goes from seconds to hours, so users retry, producing *more* messages. The broker hits memory or disk limits and starts throttling or dropping everything, including healthy traffic from other teams. Recovery is brutal: even after the consumer is fixed, it faces a multi-hour backlog of mostly-stale work before live traffic flows again. The system didn't degrade — it dug a hole and kept digging.

Assistants write open-loop producers because publish calls succeed instantly in dev and the consumer is never behind. The feedback loop is an architectural requirement that no single happy-path test will ever miss.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Apply Backpressure When Downstream Falls Behind

Every producer MUST have a feedback mechanism that slows or stops production when its downstream cannot keep up. "Publish succeeded" only means the broker took the bytes; without backpressure, a slow consumer becomes an unbounded backlog and a multi-hour recovery.

- Use the signals the transport gives you: publisher confirms and blocked-connection callbacks (RabbitMQ), `max.in.flight` and buffer-full errors (Kafka), stream `write()` returning false plus `drain` (Node), bounded channels that block the sender (Go). Never swallow them and keep sending.
- For HTTP and gRPC, treat 429 and 503 with `Retry-After` as commands, not errors to log: reduce send rate, then ramp back gradually.
- Watch queue depth or consumer lag and act at a threshold: pause intake, shed low-priority work, or return 429 to your own callers. Propagating pressure upstream to the original client is the design goal — somebody at the edge can actually slow down.
- Cap in-flight work in the producer (semaphore, bounded pool). "Accept everything and buffer" just moves the unbounded queue into your process.
- Decide explicitly what is droppable under pressure (metrics, low-value events) versus what must block (orders, payments). Dropping by accident is an outage; dropping by policy is load shedding.
- Set TTLs on time-sensitive messages so a backlog drains stale work instead of processing Tuesday's "live" notifications on Thursday.

**Red flags that you're about to violate this:**
- "Publish is async, so the producer doesn't need to care."
- "The queue absorbs spikes, that's what it's for."
- "The consumer keeps up fine." (Today. At current traffic. While healthy.)
- "I'll retry the publish until it succeeds." (Into a full broker. Harder.)
- "Slowing down the producer would hurt throughput."
- "We'll add rate limiting if it becomes a problem."

---

## Why It Works

1. **It closes the control loop.** Open-loop producers are stable only while consumers outpace them; one explicit feedback signal makes the system self-regulating under every load profile instead of one.
2. **It moves pressure to where it can be resolved.** Only the edge client can actually reduce demand; propagating 429s upstream gets the signal there, instead of letting an internal queue silently absorb the lie that capacity is infinite.
3. **It distinguishes load shedding from data loss.** Pre-deciding what's droppable means the overload response is a policy you chose, not whatever the broker's eviction algorithm felt like.
4. **It addresses recovery, not just the incident.** TTLs and shedding mean the backlog after an incident is minutes deep, not hours — the difference between a blip and a day-long degradation.

## Origin

A notifications pipeline produced push messages with no awareness of consumer lag. A bad consumer deploy cut processing speed by 80% for two hours; the producer never slowed, and the queue grew to eleven million messages. The consumer was fixed quickly — then spent fourteen hours delivering two-day-old "your driver is arriving" notifications, because nothing had a TTL and nothing had ever told the producer to stop.
