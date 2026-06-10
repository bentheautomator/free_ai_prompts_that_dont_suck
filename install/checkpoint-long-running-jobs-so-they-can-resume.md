### Checkpoint Long-Running Jobs So They Can Resume

Any job that processes a large dataset or runs longer than a few minutes MUST persist its progress and resume from the last checkpoint after a restart. Assume the process WILL be killed mid-run — by a deploy, an eviction, or an OOM — and design for the rerun, not just the run.

- Persist a durable cursor as work completes: the last processed ID, timestamp watermark, batch number, or offset, stored in a database or the job's own state table — not in process memory, not in a local file on an ephemeral disk.
- On startup, read the cursor and continue from it. Starting from zero must be an explicit operator choice, never the default.
- Process in ordered, deterministic batches (by primary key range or stable cursor) so "resume from checkpoint" has a well-defined meaning. Unordered `OFFSET` pagination shifts under you.
- Advance the checkpoint only after the batch's work is durably complete — checkpoint-then-process loses the batch on a crash between the two.
- Make each item's processing idempotent anyway (skip-if-done guard or upsert), because a crash mid-batch means the batch boundary will be replayed.
- Record per-item failures and continue; don't let item 41,007 kill a million-item run. Park failures for later review.
- Log progress (`processed 412000/1900000, cursor=812345`) so operators can distinguish "slow" from "stuck" and estimate completion.

**Red flags that you're about to violate this:**
- "The job should finish in one go, it's a single script."
- "If it fails we can just run it again from the start."
- "I'll keep a counter of where we are." (In memory. Where counters go to die.)
- "Restarts are rare, this isn't worth the complexity."
- "I'll wrap the whole thing in one big transaction." (Hours-long transactions are their own incident.)
- "We only need to run this once."
