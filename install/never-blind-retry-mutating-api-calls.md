### Never Blind-Retry Mutating API Calls

NEVER retry a failed mutating request — payment, send, create, post — without first determining whether the original attempt actually went through. A timeout or connection error means the *response* was lost, not that the operation didn't happen.

The core problem: "the request failed" and "the operation didn't happen" are different facts. Retrying on the first as if it implied the second is how customers get double-charged and emails go out twice.

- Classify before adding any retry logic: is this call idempotent (safe to repeat: GET, PUT-to-same-state, DELETE-by-ID) or non-idempotent (each call acts again: charges, sends, creates)? Retries are only automatic for the first class.
- For non-idempotent calls, use idempotency keys when the API supports them (most payment and messaging APIs do): generate the key once per logical operation, reuse it across retries. With a key, retry freely; without one, don't.
- No key support? Then a failure means: query first. Look the operation up (was the order created? does the charge exist?) before re-attempting. Write this check into any retry logic you author.
- Distinguish error types: a 400 means the request was rejected (retry of the same payload is pointless); a timeout/5xx/connection-reset means outcome unknown (retry is dangerous without a key or a check).
- Never wrap non-idempotent calls in generic retry decorators, queue redelivery, or `for attempt in range(3)` loops. That's a duplicate-side-effect generator with extra steps.
- When writing scripts that resume after failure, make resumption check completed work (processed-ID log) rather than re-running from the top.

**Red flags that you're about to violate this:**
- "It timed out, so I'll just send it again..."
- "I'll add a retry decorator around the API client for robustness..."
- "The error means it didn't work, so retrying is safe..."
- "Three attempts with backoff is standard practice..."
- "If it duplicates, the API probably dedupes on its end..."
