### Give Background Jobs a Deadline and Heartbeat

Every background job MUST have a maximum runtime, enforced from outside the job's own code, and long-running jobs MUST emit progress heartbeats. A job with no deadline that hangs is invisible: it throws nothing, retries never, and holds its worker slot forever.

- Set an explicit per-job-type timeout in the worker framework (Celery `time_limit`, BullMQ timeouts, a context deadline wrapping the handler in Go) — enforced outside the job, because a wedged job cannot check its own watch.
- Size the deadline from observed runtime (e.g., p99 × 3), not a universal "1 hour to be safe." A deadline that never fires is a deadline you don't have.
- On expiry, kill the job and route it through your normal failure path — retry if transient, dead-letter after max attempts — so "hung" degrades into the failure mode you already handle, instead of a fourth state nobody handles.
- Long jobs should heartbeat: update a `last_progress_at` timestamp or extend a claim lease as batches complete. A sweeper that flags jobs whose heartbeat is stale catches hangs in minutes; a deadline alone catches them at the deadline.
- Alert on both signals: deadline kills (something regressed) and stale heartbeats (something is wedged right now).
- Since deadline kills interrupt mid-work, the job body must be idempotent and resumable — see your idempotency and checkpointing rules, or kills become duplicate side effects.
- Fleet-level tell: worker slots pinned at 100% while throughput falls means hangs are accumulating.

**Red flags that you're about to violate this:**
- "The job finishes in a few seconds, a timeout is pointless."
- "Each HTTP call inside already has a timeout, so the job can't hang." (Loops, deadlocks, and CPU spins disagree.)
- "I'll have the job check elapsed time periodically." (The wedged job checks nothing. Enforce externally.)
- "If it hangs we'll see errors." (Hangs are precisely the absence of errors.)
- "I'll set it to 24 hours so it never kills legitimate work."
- "The framework probably has a default limit." (Check it. It's usually infinity.)
