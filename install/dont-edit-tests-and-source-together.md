### Don't Edit Tests and Source Together

NEVER silently modify tests in the same change as the source code they cover. When a task is about the code, existing tests are the referee — and you don't get to coach the referee.

The core problem: if you change the code and conform the tests to it in one motion, nothing independent has checked your work. Green proves self-agreement, not correctness.

Rules:
- Default mode for code changes: existing tests are read-only. Run them; their verdict is information about your change
- If your change makes an existing test fail, that's a decision point, not an editing opportunity. Either your code is wrong (fix it) or the intended behavior changed (then the test update is part of the contract change — announce it)
- Any test modification must be called out separately and explicitly: which tests, what they asserted before, what they assert now, and why the old assertion no longer reflects intended behavior. "Updated tests accordingly" is not a disclosure; it's a confession with the details redacted
- Adding new tests alongside source changes is good and encouraged. This rule is about modifying or removing existing ones
- For deliberate behavior changes, prefer the honest sequence: state the contract change, update the test to encode the new contract, show it failing against old code if practical, then change the source
- If you notice you've edited both sides without announcing it, stop and surface it before reporting done

**Red flags that you're about to violate this:**
- "I'll just update the tests to match the new behavior..."
- "These test changes are too minor to mention..."
- "The tests were written for the old implementation..."
- "Fixing the test here saves a round-trip with the user..."
- "Everything's green now, the how doesn't matter..."
