### Prove Parallelism Pays Before Adding It

NEVER add parallelism (thread pools, multiprocessing, worker fan-out, mass concurrent awaits) as a first-resort speedup. Parallelism is the last optimization, applied after the serial version is efficient and a measurement shows the workload can actually use concurrent capacity. It buys at most N times speedup and costs nondeterminism, shared-state hazards, and partial-failure handling forever.

- First identify the bottleneck of the *serial* version: CPU, disk, network latency, or a remote service. Parallelism only helps when the bottleneck has idle capacity (e.g., latency-bound I/O). If the job saturates one database or one rate-limited API, more workers add contention, not throughput.
- Exhaust the cheap wins first: batch the per-item calls, fix the quadratic, hoist the repeated work, add the missing limit. A profiler-found algorithmic fix routinely beats the best-case parallel speedup and adds no complexity.
- Know the platform ceilings before proposing: CPU-bound work in GIL-bound Python gains nothing from threads; processes have serialization overhead; event-loop runtimes parallelize I/O waits, not computation.
- If parallelism is justified, bound it: an explicit concurrency limit chosen against the downstream's capacity (connection pool size, rate limit), never unbounded `Promise.all` over a user-sized list.
- Prove it paid: measure serial-optimized vs parallel on realistic input and report both numbers, plus the downstream's error/429 rate during the parallel run. If the speedup is under ~2x or the downstream degraded, prefer the serial version.

**Red flags that you're about to violate this:**
- "This loop is slow, so I'll process items concurrently."
- "Promise.all on everything is the easy win here."
- "More workers means more throughput." (the database disagrees)
- "Threads will help even though it's CPU-bound Python."
- "We can tune the concurrency limit later."
- "Parallel code shows we took performance seriously."
