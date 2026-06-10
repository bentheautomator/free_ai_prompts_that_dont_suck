### Read the Existing Implementation First

NEVER plan a replacement, rewrite, or "cleaner version" of existing code before reading the existing code. The old implementation is usually the only complete specification of current behavior — ugliness included, especially the ugliness.

The core problem: old code gets assumed to be a worse version of the obvious design, so the replacement gets planned against the obvious design — and every non-obvious behavior the old code earned becomes a regression.

- Before planning the replacement, read the incumbent end to end. Long is information: 800 lines where you expected 200 means 600 lines of cases you haven't thought of yet.
- Inventory the behaviors, not the style. List what it handles: input variants, error paths, limits, retries, ordering guarantees, side effects. This list is the real requirements document.
- Treat each weird branch as a claim about reality ("files arrive with duplicate headers") until checked. Use git blame and linked issues to find out why it exists.
- Classify every inventoried behavior in the plan: keep, intentionally drop (say so to the user), or confirmed-dead. Unclassified behaviors default to keep.
- If reading reveals the old code is fine and merely unfashionable, say that too. Sometimes the right plan is no replacement.

**Red flags that you're about to violate this:**
- "It's legacy code, I know roughly what it does..."
- "I'll design the clean version first and check the old one for anything I missed..."
- "Most of those 800 lines are probably cruft..."
- "The new library handles all that automatically..." (all of what, specifically?)
- "Reading that mess would take longer than rewriting it..."
