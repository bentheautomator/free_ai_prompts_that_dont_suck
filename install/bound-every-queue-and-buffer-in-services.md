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
