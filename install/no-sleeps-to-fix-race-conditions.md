### No Sleeps to Fix Race Conditions

NEVER fix an ordering, timing, or race bug by inserting a sleep, delay, or arbitrary timeout. A sleep changes the probability of the race; it does not remove the race.

If code fails because event B ran before event A finished, the fix is to synchronize on A's actual completion, not to make B late.

- Identify the concrete event being waited for: a promise/future resolving, a transaction committing, a message acked, a file flushed, an element rendered, a service reporting ready
- Synchronize on that event directly: `await` the operation, use a callback/completion signal, a lock, a condition variable, a readiness probe, a join
- If the system genuinely offers no completion signal, poll *for the condition itself* with a bounded retry and a clear failure, never a single blind delay
- Treat any number you'd have to choose (100ms? 500ms? 2s?) as proof you're guessing; correct synchronization has no magic number to tune
- If you find an existing sleep masking a race while debugging, flag it as a bug, don't tune it upward
- In tests, the same rule applies: wait for the observable condition, not the clock

**Red flags that you're about to violate this:**
- "A small delay here should give the async operation time to complete..."
- "Bumping this from 100ms to 500ms makes it pass consistently..."
- "It's just a test, a sleep is fine here..."
- "The race is rare; the delay makes it effectively impossible..."
- "There's no clean way to know when it's done, so I'll wait a bit..."
- Choosing a duration by trying values until the failure stops
