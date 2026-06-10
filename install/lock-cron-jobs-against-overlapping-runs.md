### Lock Cron Jobs Against Overlapping Runs

NEVER schedule a recurring job without deciding what happens when a run is still going at the next tick. By default, most schedulers will happily start a second concurrent copy, and two copies of the same job double-process whatever the job touches.

- Guard every scheduled job with a mutual-exclusion mechanism that works across instances: a database advisory lock, a Redis lock with expiry (e.g., Redlock/SETNX with TTL), or the scheduler's own policy (Kubernetes `concurrencyPolicy: Forbid`, Quartz `@DisallowConcurrentExecution`, `flock` for plain cron).
- A boolean in process memory is not a lock — the next run may start on a different replica, and a crashed run leaves the boolean stuck.
- Give every lock a TTL or heartbeat so a crashed holder doesn't block the job forever. A lock that can't expire converts "double run" into "no runs ever again."
- Decide skip vs. queue explicitly: usually the right behavior is to skip the tick and log it (the work will be picked up next run). Queuing missed ticks recreates the pileup.
- Emit a metric or log when a run is skipped due to the lock, and alert if runs are skipped repeatedly — that means the job can no longer finish within its interval and needs attention.
- If the job processes rows, also make the selection atomic (`SELECT ... FOR UPDATE SKIP LOCKED` or claim-by-update) as defense in depth.

**Red flags that you're about to violate this:**
- "The job only takes a few seconds, it'll never overlap."
- "Cron handles that." (It doesn't.)
- "I'll set a flag at the start and clear it at the end."
- "There's only one instance of this service." (Until the next scale-out or blue-green deploy.)
- "Overlap is harmless here, the operations are probably idempotent."
- "I'll just make the interval longer."
