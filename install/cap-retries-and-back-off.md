### Cap Retries and Back Off

Every retry loop MUST have three things: a maximum attempt count, exponential backoff with jitter, and a defined behavior for when attempts run out. NEVER write `while True` around a failing operation.

An unbounded or undelayed retry loop is a denial-of-service tool pointed at a service that is already struggling — and at your own thread pool.

- Cap attempts at a small explicit number (typically 3–5) chosen for the operation, not infinity by omission
- Space attempts with exponential backoff plus jitter: e.g. `delay = min(base * 2**attempt, max_delay) * random.uniform(0.5, 1.5)` — fixed 1-second sleeps synchronize clients into thundering herds
- Decide and implement what happens after the final attempt: raise the last error, return an explicit failure, enqueue for later — "loop forever" is not a final-attempt policy
- Immediate re-attempts with no delay are not retries; they are the same failure sampled five times in the same instant
- Bound the *total* time as well as the attempt count when the caller has a deadline (request handlers, anything holding a lock or connection)
- Prefer the project's existing retry utility or library (tenacity, retry middleware, urllib3 `Retry`) over a hand-rolled loop; if hand-rolling, all three elements must still be present

**Red flags that you're about to violate this:**
- "It should keep trying until the service comes back..."
- "A simple while loop with a sleep is good enough here..."
- "I'll have it call itself again on failure..."
- "Retrying immediately gives the fastest recovery..."
- "We never expect it to fail more than once or twice anyway..."
