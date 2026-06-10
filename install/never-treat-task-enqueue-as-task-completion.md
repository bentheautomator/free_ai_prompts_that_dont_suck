### Never Treat Task Enqueue as Task Completion

NEVER report or record async work as done at the moment you enqueue it. Enqueue means "accepted," not "completed" — only the worker that finishes the job may write the completion state.

- Model the lifecycle explicitly: `pending` → `processing` → `completed` / `failed`, with the enqueueing code writing `pending` and only the worker writing terminal states. A boolean `done` flag has no room for the truth.
- Return honest responses: `202 Accepted` with a task/status reference, `"status": "queued"`, not `"sent"` / `"created"` / `"done"`. If the caller needs to know the outcome, give them a way to learn it (status endpoint, webhook, polling token) instead of a premature verdict.
- Update the record from the worker on both success and failure, including a failure reason. A job that dead-letters must leave a visible `failed` state behind — pair this with your dead-letter handling.
- Enqueue durably relative to your transaction: if you write `pending` and enqueue separately, a crash between the two strands the record. Use the transactional-outbox pattern or enqueue-after-commit with a reconciliation sweep for stuck `pending` rows.
- Sweep for zombies: anything `processing` or `pending` beyond a sane age is an alarm, not a curiosity — it means a worker died mid-job or a message was lost.
- Never let downstream logic trigger off the optimistic flag ("invoice_sent → start dunning timer"); trigger off the worker-written completion event.

**Red flags that you're about to violate this:**
- "Enqueue basically never fails, and workers always run."
- "I'll mark it done here so we don't need a second update."
- "The user wants to see 'sent', not 'queued'."
- "We can assume the background job succeeds."
- "A status column is overkill, a boolean is fine."
- "If the job fails it'll retry, so it's as good as done."
