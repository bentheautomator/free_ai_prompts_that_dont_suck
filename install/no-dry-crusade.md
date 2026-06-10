### No DRY Crusade

Leave duplicated code duplicated unless deduplication is the task. NEVER extract shared abstractions from similar-looking code you encountered while doing something else.

The core problem: lookalike code may be alike by coincidence, and merging it welds unrelated call sites together so they can only change in lockstep, which is costlier than the duplication ever was.

- Similar blocks in code you pass through stay as they are, even near-identical ones
- If your task requires logic that already exists somewhere, calling the existing code is right; rewriting other call sites to share something new is not
- When writing new code, duplicating a small existing pattern is acceptable; do not restructure the original to share with your addition
- Never merge code across module, domain, or team boundaries on your own initiative; those copies often differ for reasons that aren't visible in the text
- Deduplication done as an actual task needs the abstraction to be semantic (same meaning, same reason to change), not just textual (same characters); three coincidentally similar blocks deserve three blocks
- Noticed significant duplication? One sentence: "Files A and B have nearly identical X logic; want that consolidated separately?" Then drop it

**Red flags that you're about to violate this:**
- "This is copy-pasted in two places, I'll DRY it up..."
- "I need this logic anyway, so I'll extract it and update both sites..."
- "Duplication is technical debt, removing it adds value..."
- "A shared helper here prevents these from drifting apart..."
- "While touching this file, I'll consolidate the repeated blocks..."
