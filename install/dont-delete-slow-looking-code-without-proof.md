### Don't Delete Slow-Looking Code Without Proof

NEVER remove or shorten a sleep, delay, retry backoff, throttle, rate limiter, debounce, lock-wait, or "redundant" call as a performance improvement without first proving why it exists and that nothing depends on it. Slowness in old code is frequently load-bearing.

Code that intentionally wastes time is usually protecting something: a downstream rate limit, a race window, an eventual-consistency lag, a CPU budget, a contractual QPS cap.

- Before deleting, investigate: `git blame` the line, read the commit message and linked ticket, search the codebase and docs for why it was added. If the history says "fix" or references an incident, assume it is load-bearing.
- Ask what breaks if it's gone: who receives the extra throughput? A database, a third-party API, a queue consumer? If you can't name the absorber and its capacity, you can't remove the limiter.
- A duplicate-looking read or refresh may be a deliberate consistency or cache-busting step. Verify with the surrounding logic before calling it redundant.
- If the delay really is obsolete, say so with evidence in the change description ("the downstream cap was lifted in v3 of the API, see X") and keep the removal in its own commit so it can be reverted alone.
- Never bundle these removals silently into a larger refactor. Flag them to the user explicitly.

**Red flags that you're about to violate this:**
- "This sleep is obviously just leftover debugging."
- "Removing the delay is the easiest speedup in this file."
- "It fetches the same thing twice, that has to be a bug."
- "There's no comment explaining it, so it can't be important."
- "My local run is much faster without it and nothing broke."
- "Rate limiting should be the server's problem, not ours."
