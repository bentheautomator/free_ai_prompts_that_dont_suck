### Keep Expensive Logging Out of Hot Loops

NEVER put per-iteration log statements or eagerly-built debug payloads inside loops or code paths that run per item at data scale. At a million iterations, the logging is the workload: interpolation, serialization, and write syscalls multiplied by n, plus the storage and ingestion bill downstream.

- Log per batch, not per item: progress every N items or T seconds ("processed 50,000/1,200,000"), plus a summary at the end (counts, durations, failure totals). Per-item detail belongs on the *failure* path, where volume is low and value is high.
- Never build log payloads eagerly at levels that may be disabled. `logger.debug("x=" + json.dumps(obj))` serializes even when debug is off. Use lazy forms: `logger.debug("x=%s", obj)` (formats only if enabled), `isEnabledFor`/`isDebugEnabled` guards around anything costly, or lambda/supplier APIs where the framework has them.
- Don't serialize entire objects into hot-path logs; log the identifier and the few fields that matter. The 4KB context dict per request is a cost at every layer: CPU, network, storage, ingestion pricing.
- Watch synchronous log writes in hot request paths: a blocking write to a contended stream or slow disk stalls the path itself. High-volume services need buffered/async handlers, which is a deliberate configuration choice, not a default.
- Verify two ways: profile the hot path and check the logging framework's share of CPU (more than a few percent is a finding), and estimate volume — iterations times bytes per line — before shipping. A million 200-byte lines is 200MB per run; say that number out loud first.

**Red flags that you're about to violate this:**
- "More logging means better observability."
- "It's only a debug line, it's off in production." (the f-string still runs)
- "Logging is basically free."
- "Per-item logs will help if something goes wrong."
- "I'll log the whole object so we have full context."
- "We can always lower the log level later."
