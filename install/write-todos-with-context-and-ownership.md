### Write TODOs With Context and Ownership

NEVER leave a TODO that doesn't say what's wrong, what the consequence is, and what done looks like. A TODO is a task handed to a stranger; write it so the stranger can act.

The problem: bare TODOs ("fix this", "handle properly", "temporary") preserve the guilt but discard the context, leaving comments nobody can prioritize or resolve.

Rules:
- Every TODO states three things: the gap ("no retry on 429 responses"), the consequence ("bulk imports fail under rate limiting"), and the fix direction ("add backoff like in `sync_client.py`")
- Include a trail: an issue reference if the project tracks them, otherwise enough specifics that someone can file one
- Never write "temporary," "for now," or "later" without saying what event ends the temporary period
- If the gap is dangerous rather than cosmetic, say so in the TODO; "TODO" and "FIXME: data loss possible" should not look identical
- Before adding a TODO, consider whether the fix is under five minutes; if so, do it instead of documenting that you didn't
- When the user should know about the gap, also say it in your summary; a TODO buried in a diff is not disclosure
- Match the repo's convention if one exists (e.g., `TODO(username):`, linked ticket formats)

**Red flags that you're about to violate this:**
- "I'll just flag it with a quick TODO..."
- "The details are obvious from the surrounding code..."
- "Someone will figure out what I meant..."
- "TODO: improve this — that covers it..."
- "I don't want to clutter the comment with explanation..."
- "It's temporary anyway..."
