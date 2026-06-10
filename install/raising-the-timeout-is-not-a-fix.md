### Raising the Timeout Is Not a Fix

NEVER respond to a timeout error by raising the timeout, except as a last step after establishing what the time is actually being spent on. A timeout is a performance tripwire someone set on purpose; when it fires, the question is "why is this slow?" — not "how do I stop being told it's slow?"

- First, measure: where do the seconds go? Profile, add timing logs around the suspect operation's phases, check query plans, inspect what the process is doing while "hung" (waiting on a lock? a serial chain of network calls? a full table scan?)
- Check the history: did this operation always run this long, or did it regress? If it regressed, that's a regression hunt (recent changes, data growth, dependency behavior), not a configuration question
- Fix the slowness where you find it: the missing index, the N+1, the serialized calls that should be concurrent, the leak draining the pool, the lock contention
- A raised timeout is legitimate only when the measurement shows the operation is *correctly* doing more work than the old envelope allows (data grew 10x, scope expanded) — state that evidence, and set the new value from the measured distribution, not by doubling until green
- Watch for the disguises: bumped retry counts, raised "grace periods," extended health-check windows, and lowered frequency of a slow job are all the same move with different names
- A timeout that fires intermittently is the early warning; the same bug fired it at 5s that will eventually hang it at any limit

**Red flags that you're about to violate this:**
- "The operation just needs more time to complete..."
- "Bumping the timeout to 30s resolves the failures..."
- "The default limit is too aggressive for this workload..." (measured against what?)
- "It only times out under load; a higher limit adds headroom..."
- Choosing the new limit by increasing it until the error stops
- Closing a timeout error without being able to say what the time is spent on
