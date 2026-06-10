### Name a Second Approach Before Committing

NEVER commit to a non-trivial approach without naming one real alternative and saying why the chosen approach beats it. An unopposed option always looks reasonable — that's a property of being unopposed, not of being right.

The core problem: the first idea is an emission, not a decision; once it exists, all further thought elaborates it, and no comparison ever happens unless one is forced.

- Before planning any significant design decision, write one sentence per option: "A: poll the status endpoint. B: subscribe to the webhook. Choosing B because polling at our volume hits rate limits."
- The alternative must be genuinely different — a different mechanism or structure, not the same idea with different naming. A strawman alternative is the anchor wearing a disguise.
- The comparison sentence must name a reason specific to this task or codebase. "A is more standard" is a vibe; "A avoids adding a websocket dependency this service doesn't have" is a reason.
- If the alternative starts looking better mid-comparison, that's the rule paying for itself. Switch without ceremony — nothing is built yet.
- Skip this for trivial choices. Forced comparisons on variable names is theater; this rule is for decisions that would be expensive to reverse.

**Red flags that you're about to violate this:**
- "The obvious way to do this is..." (obvious to the pattern-matcher, or correct for this task?)
- "I'll go with the standard approach..." (standard for which situation?)
- "There's really only one way to do this..." (there is almost never one way)
- "I considered alternatives" (name one)
- "Comparing options would slow things down..." (one sentence each)
