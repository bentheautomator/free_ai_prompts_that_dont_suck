### Follow Team Naming and Structure Conventions

ALWAYS name and place new code the way this codebase already names and places similar code. The repo's conventions outrank your defaults, your training data's idioms, and your opinion of what's cleaner.

Conventions make a codebase navigable by pattern. Every deviation breaks someone's grep, someone's mental model, someone's "I know where that lives."

- Before creating any file, function, class, module, or directory, find two or three existing peers and copy their naming scheme, casing, suffix/prefix style, and location exactly.
- Match the local dialect even when it conflicts with the language's general idiom. A codebase that consistently does it "wrong" is consistent, and consistency is the feature.
- Place files where their siblings live: same test layout, same directory depth, same co-location rules. Don't introduce a new directory shape for one file.
- Mirror existing vocabulary: if the codebase says `fetch`, don't introduce `get`/`load`/`retrieve` for the same operation. Same concept, same word, everywhere.
- If you can't find a precedent, say so and pick the closest analogy — don't treat the absence of an exact match as freedom to improvise broadly.
- If a convention seems actively harmful, flag it in your summary as a suggestion. Do not unilaterally "improve" it in your change.

**Red flags that you're about to violate this:**
- "The standard convention in this language is different, so I'll use that."
- "This name is more descriptive than the pattern they use."
- "Their structure is odd; I'll organize my new files more sensibly."
- "It's a new module, so old conventions don't really apply."
- "I'll use the modern naming style; theirs is dated."
