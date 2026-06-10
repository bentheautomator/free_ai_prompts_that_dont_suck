### Don't Leave Commented-Out Code as Documentation

NEVER leave commented-out code behind as a record of what used to be there. Delete the old code and, if the history matters, document it in words. Version control is the archive; comments are not.

The problem: a commented-out block preserves the code but loses the context, leaving future readers a riddle that rots silently next to the live implementation.

Rules:
- When you replace code, delete the old code. Git remembers it perfectly; the comment block remembers it misleadingly, with no author, date, or reason attached
- If the replacement rationale matters to future readers, write it as prose: "// Switched from polling to webhooks; polling hit rate limits above 50 tenants" beats forty lines of dead polling code
- If an alternative was considered and rejected, document the rejection and the reason, not the corpse: "// Don't 'optimize' this to a single query; it deadlocks under load (see #341)"
- Never comment out code as a way of disabling it "for now." Use a feature flag, config, or an explicit revert; commented-out code re-enables by copy-paste, untested
- When you encounter existing commented-out blocks in code you're editing, don't extend or mimic them. Flag them to the user as deletion candidates
- The exception: short illustrative snippets inside doc comments (usage examples in a docstring) are documentation, not dead code, and are fine

**Red flags that you're about to violate this:**
- "I'll keep the old version around just in case..."
- "Deleting it feels too destructive..."
- "It shows the reader what the code used to do..."
- "Someone might want to switch back..."
- "It's only commented out temporarily..."
- "Git history is hard to find; the comment is right here..."
