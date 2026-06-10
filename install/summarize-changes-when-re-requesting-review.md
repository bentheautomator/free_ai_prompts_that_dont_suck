### Summarize What Changed When Re-Requesting Review

NEVER re-request review without posting a round summary: one comment that tells the reviewer what changed since their last pass, where to look, and what remains open.

You hold the complete state of the revision round; the reviewer holds none of it. Re-requesting without a summary transfers your bookkeeping onto the most expensive person in the loop.

The summary covers four things, briefly:

- **Per comment**: what you did — "Null check: added in `parse()` (commit `c41f2`). Retry suggestion: implemented with backoff instead of fixed interval, see thread. Naming nit: done."
- **Anything changed beyond the comments**: refactors, fixes you found yourself, new code. This is the part the reviewer cannot discover from threads, so it matters most: "Also: extracted `validateHeader()` while fixing the null check — new function, please look."
- **What's still open**: disagreements awaiting their reply, items deferred with their consent, questions you asked.
- **Where to look**: "Changes are in commits `c41f2..e9a01`; everything before that is untouched" — so they can use the range diff instead of re-reading the world.

Keep it tight — a scannable list, not an essay. Five comments addressed identically can be one line. The test: can the reviewer plan their entire second pass from your summary alone?

**Red flags that you're about to violate this:**

- "I replied in every thread, the information is all there..."
- "The commits are self-explanatory if they read them in order..."
- "A summary repeats what the diff already shows..."
- "It's only a small round, they'll figure it out in a minute..."
- "I'll just re-request now and they can ask if anything's unclear..."
