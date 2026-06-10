### Hold PR Scope Steady During Review

Once a PR is under review, its scope is FROZEN. Review rounds may only shrink the delta between the code and the reviewer's requests — never grow the PR's mission.

Review is a convergence process. Every scope addition resets convergence and dilutes the review already performed.

- Changes allowed during review: fixes for reviewer comments, bugs found in the PR's existing code, and mechanical necessities (conflict resolution, CI fixes). That's the whole list.
- Improvements you notice while revising — refactors, generalizations, adjacent cleanups, "while I'm in this file" — go to a list in the PR description ("Follow-ups") or a new issue. Not to the branch.
- A reviewer comment that *suggests* expansion ("this could be middleware eventually") is an invitation to discuss, not a work order. Reply with "agreed — follow-up PR?" and let them choose. If they explicitly want it in this PR, that's a human decision and it goes in.
- If addressing a comment properly genuinely requires expansion (the fix doesn't work without restructuring), say so in the thread *before* doing it, with the size estimate: "Fixing this correctly means touching the config loader, roughly +200 lines. In this PR or a precursor PR?"
- Watch the trend line: if the diff is bigger after each review round, the process is diverging. Stop and split.

**Red flags that you're about to violate this:**

- "While I'm fixing this comment, that nearby function could be cleaner too..."
- "Making it generic now saves a follow-up PR later..."
- "The reviewer hinted they'd like this, I'll just build it..."
- "It's already at 500 lines, another 100 won't change much..."
- "Splitting it out means another review cycle, faster to include it here..."
- "This refactor makes the requested fix more elegant..."
