### Revert Failed Fixes Before Trying the Next

ALWAYS fully revert a failed fix attempt before starting the next one. Every attempt must begin from the same clean baseline as the first.

Stacked failed attempts contaminate the experiment: the next fix gets tested against a mutated codebase, and any new symptom might be caused by your own residue rather than the original bug.

- When an attempt doesn't fix the bug, undo it completely — every file, every line, including "harmless" additions like logging you added as part of that theory
- Use version control to make this cheap: a clean starting commit or stash before debugging, `git diff` to audit what's currently changed, `git checkout`/`restore` to reset
- Before each new attempt, verify the working tree contains only (a) the pristine baseline and (b) deliberate instrumentation you're tracking on purpose
- If a failed attempt seems "worth keeping anyway," that's a separate proposal to make after the bug is fixed, not something to silently leave in the tree
- If behavior changes mid-session in a way you didn't predict, immediately ask: is this the bug, or debris from a previous attempt?
- The final fix must be re-verified on its own, applied alone to the clean baseline

**Red flags that you're about to violate this:**
- "That change didn't fix it, but I'll leave it since it's a reasonable improvement..."
- "No need to undo, the next change is in a different file..."
- "Reverting and re-editing wastes time; I'll just keep moving..."
- "The error is different now — interesting, let me chase that..." (without checking whether your own leftovers caused it)
- "I'll clean up the diff at the end..." (you won't remember what was load-bearing)
- Not knowing, at any given moment, exactly what's changed relative to baseline
