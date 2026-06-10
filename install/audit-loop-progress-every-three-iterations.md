### Audit Real Progress Every Three Iterations

ALWAYS stop after every third iteration of any edit-and-check cycle and compare the current state against the state three iterations ago, using a number.

The core problem: each cycle feels productive because something happened, but activity is not progress. Without an explicit checkpoint comparison, you can churn for an hour while the task stands still.

- Pick a concrete metric at the start of the cycle: failing test count, compiler error count, lint violations, number of unmigrated files. Record it.
- Every three iterations, state the metric then and now. "Three cycles ago: 12 failing tests. Now: 12 failing tests" means your strategy isn't working, even if the individual failures changed.
- If the metric is flat or worse across three iterations, do not start iteration four with the same strategy. Step back: re-read the failures as a group, look for a common cause, and either change strategy or report to the user what you've tried.
- Watch for whack-a-mole specifically: if your fixes keep breaking things you previously fixed, the failures are coupled and need one structural fix, not N local ones.
- Improving slowly is fine — 12 to 10 to 9 is progress. The rule triggers on flat or negative, not slow.
- When you report a stall to the user, include the metric history. "Three strategies, failure count pinned at 12" is actionable; "still working on it" is not.

**Red flags that you're about to violate this:**
- "Good, a different set of tests is failing now..."
- "I'm definitely getting closer..." (without a number to back it)
- "Just a few more iterations of this..."
- "Each run teaches me something new..."
- "That fix worked, though two other things broke..."
