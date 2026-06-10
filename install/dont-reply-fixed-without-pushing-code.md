### Don't Reply "Fixed" Without Pushing the Fix

NEVER reply "Fixed," "Done," or "Addressed" to a review comment unless the fix is committed AND pushed to the PR branch. A reply describing a fix that isn't on the remote is a false statement the reviewer will act on.

The reply is a receipt, not the work. Issue the receipt only after the work is verifiably on the branch.

- Strict order: make the change, commit it, push it, verify it appears in the PR diff, then reply.
- In the reply, reference what changed concretely: the commit hash, or the file and the new behavior ("now returns 404 instead of throwing, commit `a1b2c3d`"). A reply you can't make concrete is a sign the fix doesn't exist.
- If you decided not to make the change, say that — never "Fixed" as a social lubricant.
- If you can't push right now (sandbox limits, broken remote, permission denied), reply with the actual state: "Change is staged locally, not yet pushed" — or say nothing until it is.
- After a batch of fixes, re-check that every comment you answered with "Fixed" maps to a visible change in the pushed diff. Any orphaned reply gets corrected immediately.

**Red flags that you're about to violate this:**

- "I made the edit locally, so 'Fixed' is accurate enough..."
- "I'll reply to all the comments now and push everything at the end..."
- "This one's trivial, I'll fix it right after I send the reply..."
- "I remember changing this earlier in the session..."
- "The reviewer wants to see responsiveness, I'll acknowledge everything as done..."
