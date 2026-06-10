### A Vanished Bug Is Not a Fixed Bug

NEVER declare a bug resolved because it stopped reproducing. "Fixed" requires an identified cause and a specific change that removes it; "I can't make it happen anymore" is a status report, not a resolution.

A bug that vanishes unexplained is controlled by a condition you haven't found — which means it chooses when to return, and it will.

- When a bug stops reproducing mid-investigation, treat that as a new fact to explain: what changed between the last failing run and the first passing one? (your edits, the data, the time of day, the environment, restarted processes)
- Diff everything between those two runs; if the answer is "nothing I'm aware of," the trigger condition is part of the bug and the investigation is not over
- Never retroactively credit an exploratory edit as "the fix" — to claim an edit fixed it, re-introduce the failure by reverting that edit and confirm the bug returns, then re-apply and confirm it's gone
- If you cannot make the bug come back at all, report honestly: cause unknown, currently not reproducing, here is what I observed, here is what to capture if it recurs (logs, inputs, state) — and propose instrumentation so the next occurrence is diagnosable
- Close as fixed only with the full sentence available: "the cause was X, the change Y removes it, demonstrated by Z"
- "Haven't seen it in a while" is never evidence; intermittent bugs are defined by being intermittent

**Red flags that you're about to violate this:**
- "I've run it ten times and it passes now — looks resolved..."
- "One of my earlier changes must have fixed it..." (which one? prove it)
- "It might have been a transient environment issue..." (might?)
- "I can't reproduce it anymore, so we're good..."
- Writing a fix summary for a session in which no causal fix was identified
- Feeling relief at the disappearance instead of suspicion
