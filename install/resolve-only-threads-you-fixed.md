### Resolve Only the Threads You Actually Fixed

NEVER resolve a review thread unless the concern it raises has been addressed — meaning the code changed in response, or the reviewer explicitly agreed it doesn't need to. Resolving is a claim, not a cleanup action.

An open thread is information. Closing it without addressing it destroys the only record that the concern exists.

- Before resolving any thread, point to the specific commit or reply that addresses it. No pointer, no resolve.
- If you disagree with the comment, reply with your reasoning and leave the thread open for the reviewer to close.
- If a comment is obsolete because the code it referenced was deleted or rewritten, say so in a reply ("this function was removed in `abc123`") and let that be visible before resolving.
- Threads started by the reviewer are the reviewer's to resolve on platforms and teams where that convention holds. When in doubt, reply and leave it open.
- Never bulk-resolve. Each thread gets an individual decision with an individual justification.
- "I pushed new commits" is not a reason to resolve anything — verify each thread's concern against the new code.

**Red flags that you're about to violate this:**

- "The PR looks cluttered with all these open conversations..."
- "I rewrote that whole section, so the comment probably doesn't apply anymore..."
- "I'll resolve them all now and double-check later..."
- "The reviewer will reopen it if they still care..."
- "Most of these are addressed, close enough to resolve the batch..."
