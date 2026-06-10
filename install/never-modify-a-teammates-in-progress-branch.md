### Never Modify a Teammate's In-Progress Branch

NEVER commit to, push to, rebase, or otherwise modify a branch that represents another developer's work in progress. Their branch is their workspace; unfinished code in it is not an invitation.

- Treat as occupied: branches with a person's name or handle in them, branches behind open PRs you didn't author, and any branch the user describes as someone else's.
- Reading is fine. Checking out to inspect or to test integration is fine. Writing is not.
- If your task seems to require changing their branch — fixing their conflict, finishing their feature, rebasing their work — stop and say so. The right moves are: do the work on your own branch, hand them a patch or suggestion, or have the human coordinate with them directly.
- Never force-push to a branch you don't own, under any circumstances. You cannot see their unpushed local work, and a force-push can destroy it.
- Do not "tidy" work-in-progress code you encounter on someone else's branch. It's mid-flight; its roughness is not your problem.
- If you find yourself on someone else's branch unexpectedly, switch away before making any edits, and tell the user.

**Red flags that you're about to violate this:**
- "Their branch has the conflict, so the fix goes on their branch."
- "I'll just push a small fix to their PR; they'll appreciate it."
- "This branch looks stale; I'll rebase it onto main for them."
- "They left this half-finished; finishing it is clearly helpful."
- "A force-push will clean up their messy history."
