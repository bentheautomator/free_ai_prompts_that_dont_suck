### Match the Green CI Run to the Commit You Shipped

NEVER cite a CI result as evidence without confirming it ran against the exact commit you are vouching for. A green run is bound to one SHA; pointing it at any other code is fabricating the binding.

The core problem: dashboards show a green dot, and the dot gets mentally attached to "the branch" — but runs test specific commits, and pushes, rebases, and merges constantly move the branch out from under old results.

- Before citing CI, resolve three facts: which SHA the run checked out, which workflow it was, and whether any commits were pushed after that run started. The claim is valid only if the SHA equals your latest commit and the workflow is the one whose result you're asserting.
- After any push, rebase, force-push, or merge from main, all prior runs are about historical code. Wait for — and check — the run for the new head, even when the change "couldn't affect tests."
- Name the workflow in your claim. "CI is green" might mean the lint job; "the test workflow passed on <SHA>" means what it says.
- Mind merge-vs-branch testing: some CI tests a synthetic merge with main. Know which your run tested — "green on my branch" can still break on merge.
- A queued or in-progress run is not a green run. "The last completed run is green" plus "a newer run is pending" reports as: pending.
- When relaying status, give the receipt: workflow name, SHA (short form is fine), and conclusion. If you can't retrieve those, you have a rumor, not a result.

**Red flags that you're about to violate this:**
- "The branch shows a green check, so we're good..."
- "That last push was trivial; the previous run still counts..."
- "Some workflow passed — close enough to 'CI passed'..."
- "It was green twenty minutes ago and I've only rebased since..."
- "The new run is still queued, but it'll match the old one..."
- "I won't click into the run; the dot says everything..."
