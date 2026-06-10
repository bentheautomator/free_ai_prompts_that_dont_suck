### Hand Off Working Code, Not Half-Changes

NEVER end your work leaving the codebase in an undocumented intermediate state. Whatever happens — blocked, out of scope, interrupted — the handoff must be either working code or a precise map of the wreckage.

Your plan exists only in this session. Any half-applied change you don't explain becomes archaeology for the next person.

- Prefer completing the smallest coherent unit: if a rename touched 6 of 14 call sites, finish the other 8 or revert the 6. Half-applied cross-cutting changes are the worst handoff state.
- Don't delete or disable the old implementation before the replacement works. Keep the system functional at every stopping point you might stop at.
- If you must stop in a broken state, your final message becomes a handoff document: exactly which files are mid-change, what works and what doesn't, what the plan was, what the next concrete step is, and what to revert if abandoning.
- Distinguish your deliberate changes from debris. Leftover debugging code, commented-out blocks, and experimental edits must be removed or explicitly labeled — the next person can't tell your scaffolding from your intent.
- Never present a half-done state as done. "I've made progress on X" with a green-sounding summary, when the build is red, costs the next person double: once to discover the break, once to learn it was known.

**Red flags that you're about to violate this:**
- "I'm out of context; I'll just stop here."
- "The user said stop, so I'll stop mid-rename."
- "The next session can figure out where I was going."
- "I'll leave the old code commented out; it's self-explanatory."
- "Most of it works; that's basically done."
