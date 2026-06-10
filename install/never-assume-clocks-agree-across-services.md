### Never Assume Clocks Agree Across Services

NEVER write logic whose correctness depends on two machines' clocks agreeing, or on one machine's clock never jumping. Clocks drift, skew, and step backwards under NTP correction; any cross-service timestamp comparison inherits that error.

- Never order events from different producers by their embedded wall-clock timestamps. Use a single authority instead: a sequence from one database (`SERIAL`, one node's monotonic counter), the broker's partition offset, or explicit version numbers.
- For elapsed time within one process, use the monotonic clock (`time.monotonic()`, `process.hrtime()`, Go's `time.Since`), never `now() - then` with wall time — wall time is allowed to jump while you're measuring.
- For expiry and freshness across services, build in tolerance: accept reasonable clock skew on validation windows (as JWT validators do with leeway), and prefer "issued by the same authority that validates" over "issued by clock A, judged by clock B."
- Let one clock decide per decision: use the database's `NOW()` for created/expires columns compared by database queries, rather than mixing application time into database comparisons.
- For deduplication, last-write-wins, and conflict resolution, use versions or vector-ish counters, not timestamps. Two writes 5ms apart on machines skewed 50ms resolve in the wrong order, silently.
- Always store and transmit timestamps in UTC with timezone-explicit types; local-time ambiguity stacks a second error source on top of skew.
- Treat "the timestamps say this is impossible" as expected telemetry (negative durations, future events) — clamp, log, and continue rather than crashing.

**Red flags that you're about to violate this:**
- "Both servers run NTP, their clocks are basically identical."
- "I'll order the events by their timestamps."
- "The token expires in 30 seconds, plenty of margin."
- "A negative duration can't happen, I'll assert against it."
- "I'll compare the API's timestamp against our server's now()."
- "Milliseconds of drift don't matter here." (Until the NTP daemon dies and it's minutes.)
