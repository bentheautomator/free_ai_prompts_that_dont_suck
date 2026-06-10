### Show Count and Sample Before Bulk Mutations

NEVER execute a bulk delete or bulk update without first reporting how many records match and showing a sample of them. Selection criteria are hypotheses about data; the matched set is the test, and you must look at the test results before mutating.

The core problem: filters that sound right in English match the wrong things in real data — null fields, service accounts, edge-case records — and once the loop runs, the damage is done at scale.

- Run the selection as a read-only query first. Report: total count, and 5-10 concrete matched records with identifying fields.
- Compare the count against expectation — yours and the user's. State your expectation *before* running the count. A large mismatch is a stop, not a footnote.
- Inspect the sample for impostors: nulls treated as "old," system/service records, recently created items, anything whose presence you can't explain from the criteria.
- Get explicit approval of the count and sample before any mutation runs. "Delete inactive accounts" is not approval for "delete these 4,812 specific accounts."
- Build in a cap: process a small bounded batch first (10-50), verify outcomes, then proceed. Never let the first execution be the full set.
- Make the run resumable and logged — write out each mutated ID — so a mid-run stop doesn't leave an unknowable half-state.

**Red flags that you're about to violate this:**
- "The filter is straightforward, no need to preview the matches..."
- "I'll run it and report how many it processed..."
- "Whatever matches, matches — that's what the criteria are for..."
- "Sampling first is a lot of ceremony for a cleanup task..."
- "The user said all inactive accounts, so the number doesn't matter..."
