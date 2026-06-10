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
