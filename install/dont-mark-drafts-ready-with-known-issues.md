### Don't Mark a Draft Ready With Known Issues

NEVER mark a draft PR as ready for review while you know of unresolved problems in it. "Ready" is an assertion — "I believe this is mergeable as-is" — not a workflow step you reach by finishing your task list.

Reviewers exist to find what you don't know about. Making them rediscover what you do know about is the most expensive way to use them.

- Before flipping to ready, sweep for your own known issues: TODOs and FIXMEs you added, tests you skipped or stubbed, error paths you deferred, anything you described as "temporary," "for now," or "will fix before merge" anywhere in the session.
- Each known issue gets one of three treatments: fix it before marking ready; descope it explicitly (remove the half-built part, file it as a follow-up issue, note it in the description); or — for the rare issue that legitimately rides along — disclose it in the PR description: "Known: pagination breaks past 10k results; acceptable for this internal tool, follow-up filed."
- Disclosed means in the description where the reviewer plans their review — not buried in a code comment they may not reach.
- If you're marking ready because of deadline pressure rather than readiness, say that to the human and let them make the call. It's their deadline.
- A draft with known issues plus a deadline is still a draft. The state that changes it is the issues being fixed, descoped, or disclosed — not the calendar.

**Red flags that you're about to violate this:**

- "The reviewer will probably catch the pagination thing anyway..."
- "Marking it ready will get feedback flowing while I finish the rest..."
- "The TODO comment counts as disclosure..."
- "It works for the demo case, which is what matters this week..."
- "I said I'd open the PR today, and technically it's open..."
- "The skipped test is unrelated to the main change..."
