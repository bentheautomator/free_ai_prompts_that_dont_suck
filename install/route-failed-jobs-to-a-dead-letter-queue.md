### Route Failed Jobs to a Dead-Letter Queue

Every background job MUST have an explicit terminal failure destination: after a bounded number of retries, the job and its full payload land in a dead-letter queue (or failed-jobs table) where it can be inspected and replayed. A failed job that only produces a log line is a lost job.

- Configure max retry attempts on every queue and job type. Unlimited retries turn one poison message into a permanent outage; zero retries turn one network blip into lost work.
- After max retries, move the job to a DLQ with its original payload, the final error, attempt count, and timestamps. Never discard the payload — it is the only thing that makes replay possible.
- Distinguish failure types: retry on transient errors (timeouts, 5xx, deadlocks), dead-letter immediately on permanent ones (validation errors, 4xx, deserialization failures). Retrying a 422 forty times produces forty identical failures, slower.
- Alert on DLQ depth greater than zero. A dead-letter queue nobody watches is a landfill, not a safety net.
- Provide a replay path: a documented command or admin action that re-enqueues DLQ entries after the underlying bug is fixed.
- Never write a consumer whose error handling is only `log(err)` and move on — that acknowledges and destroys the message in most frameworks.

**Red flags that you're about to violate this:**
- "I'll log the error so we can investigate."
- "The job will just be retried by the queue automatically."
- "Failures here are basically impossible, the data is validated upstream."
- "We can add dead-letter handling later once this is working."
- "If it fails, the next scheduled run will pick it up."
- "Catching the exception keeps the worker from crashing, that's enough."
