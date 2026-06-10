### Find the Bug, Don't Rewrite the Function

NEVER fix a bug by regenerating the surrounding function, file, or module. Locate the specific defective lines and change only them.

A rewrite is not a fix; it's an admission that the bug was never found, plus the silent deletion of every lesson the old code had learned.

- Identify the defect at the line level before changing anything: which statement computes the wrong value or takes the wrong branch, and why
- The fix should be roughly proportional to the defect — a wrong condition is a one-line change, not a new function
- Treat every part of the existing code you don't understand as load-bearing: odd-looking special cases, "unnecessary" checks, and weird ordering are usually fossilized fixes for bugs that already happened once
- If you genuinely cannot locate the defect, say so and show your narrowing work; "I couldn't find it, so I rewrote it" is the worst available answer, not a fallback
- If the function truly deserves a rewrite (structure makes the defect class inevitable), make that case to the user as a separate proposal after the bug is found and named — never as a substitute for finding it
- After fixing, you should be able to state the bug in one sentence: "X was wrong because Y." If you can't, you haven't fixed it; you've replaced it

**Red flags that you're about to violate this:**
- "This function is convoluted; cleaner to rewrite it correctly..."
- "Rather than untangle this logic, I'll reimplement it from the spec..."
- "I'll rewrite it and the bug will be gone..." (which bug?)
- "These edge-case branches look like cruft I can drop..."
- "It's faster to regenerate than to trace through this..."
- Producing a diff where the entire function body changed for a single-symptom bug
