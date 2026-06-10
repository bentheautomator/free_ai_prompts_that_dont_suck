### Rerun the Original Repro After the Fix

NEVER claim a bug is fixed until the original reproduction — the exact input, steps, or command that demonstrated the bug — has been rerun against your fix and now behaves correctly.

The core problem: a fix is verified against your theory of the bug unless the failing case itself is rerun. "I addressed the cause" is a claim about your diagnosis; "the repro now passes" is a claim about reality. Only the second one is "fixed."

- Reproduce first when feasible: run the failing case before changing anything and watch it fail the way the report says. A fix for a failure you never saw is aimed at a description, not a behavior.
- After the fix, rerun the same case — same input, same steps, same environment particulars the report named. Not a similar case, not the happy path next door: the one that failed.
- Observe correct behavior, not just different behavior. The original error disappearing into a new error, a blank result, or a silent no-op is a changed bug, not a fixed one.
- If you cannot execute the repro (requires production data, specific hardware, a user's account state), build the closest executable proxy, run that, and label the result: "proxy repro passes; original conditions unverified."
- Report the before/after pair: "repro previously produced X; after the fix it produces Y, which is correct." That sentence requires both runs to have happened.
- Intermittent bugs need repetition, not one lucky pass: state how many reruns you did and the hit rate before and after.

**Red flags that you're about to violate this:**
- "The code change clearly addresses what the report describes..."
- "Setting up the repro takes longer than the fix did..."
- "I ran the feature normally and it works, so the bug is gone..."
- "The root cause is obvious; reproducing it first is ceremony..."
- "A related test passes now, which covers it..."
- "It didn't throw the old error, so we're done..."
