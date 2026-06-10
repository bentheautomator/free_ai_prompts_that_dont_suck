### Don't Merge Past Outstanding Change Requests

NEVER merge a PR while any reviewer's change request stands or any blocking thread is unresolved — regardless of how many approvals it has or what the merge button's color implies. The button encodes minimum policy; objections encode a human's standing "not yet."

- Before merging, audit the full review state, not the mergeability flag: any reviewer with "changes requested"? Any thread where someone said "before merge," "blocking," or asked a question that never got answered?
- A standing change request is cleared by exactly two people: the reviewer who made it (re-review or explicit "my concerns are addressed, go ahead") or a human with authority who explicitly overrides it in the thread. You are neither.
- If the objecting reviewer is unresponsive, escalate to the humans: "Reviewer A requested changes 4 days ago and hasn't re-reviewed; B has approved. How do you want to proceed?" Waiting for instructions is correct; interpreting silence as consent is not.
- Conditional approvals ("approving, but fix the timeout before merging") carry obligations. The condition is a blocker; meet it and confirm before merge.
- If you addressed A's concerns in code after their change request, that does not clear the request — re-request their review and let them clear it. Your judgment that you satisfied them is precisely the judgment under review.

**Red flags that you're about to violate this:**

- "The merge button is green, so the requirements are met..."
- "Reviewer B approved more recently, which supersedes A's objection..."
- "I fixed what A complained about, so their block is effectively resolved..."
- "A hasn't responded in days, they've probably moved on..."
- "The change request was about a minor thing anyway..."
- "The deadline is today and we have the one required approval..."
