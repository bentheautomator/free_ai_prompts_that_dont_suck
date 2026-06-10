### Escalate When Every Batch Item Fails

A batch loop that tolerates per-item failures MUST also detect systemic failure and abort. One hundred percent failure is not a data-quality issue — it means the system is broken, and the loop should stop and say so immediately.

- Track failures during the run, not just after: keep a failure count and check it against a threshold as the loop proceeds
- Abort early on consecutive failures from a cold start: if the first N items (e.g. 10–25) all fail, stop — the probability that your first 25 records are all individually bad is negligible compared to the probability that the credential, schema, or endpoint is broken
- Abort on failure *rate* mid-run: pick a threshold defensible for the dataset (e.g. >20% after a meaningful sample) and stop when crossed, raising an error that states the rate and a sample of the underlying exceptions
- When failures share one exception type and message, say so in the abort error — "all 25 failures: AuthenticationError" hands the operator the diagnosis
- Stopping early preserves options: items not yet attempted can be retried cleanly after the fix; items churned through a broken dependency may have half-executed side effects
- Distinguish error classes where possible: infrastructure errors (connection, auth, timeout) should trip the abort threshold faster than data errors (validation), because they're never the item's fault
- The threshold values are judgment calls — make them named constants with a comment, so they're visible and adjustable, not buried magic

**Red flags that you're about to violate this:**
- "The per-item handler already covers failures..."
- "Skip and continue — that's what batch resilience means..."
- "Counting failures mid-run is overengineering..."
- "Even if many fail, processing the rest is still progress..."
- "We'll see the failure totals in the summary at the end..."
