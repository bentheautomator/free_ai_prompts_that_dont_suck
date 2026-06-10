### Don't Introduce a Rival Pattern

NEVER introduce a new pattern for a problem the codebase already solves an established way. Before writing the structural parts of a change — data fetching, error handling, dependency wiring, validation, state management — find two or three existing examples and match them.

A second pattern doesn't replace the first one; it coexists with it forever, and every reader pays for both.

- Before structuring new code, open the most recently touched files that do the same kind of thing; their shape is the spec
- Match the codebase even where your preferred pattern is genuinely better — consistency beats local optimality, because the next maintainer extrapolates from what exists
- This covers mechanisms, not just style: don't add a DI container to a constructor-injection codebase, an event emitter to a direct-call codebase, exceptions to a result-type codebase, or a new folder convention to an established layout
- If the existing pattern truly cannot express what the task needs, say so explicitly and propose the new pattern as a decision for a human — don't smuggle it in inside a feature diff
- If the codebase has two competing patterns already, match the one in the area you're touching, or the more recent one; don't add a third

**Red flags that you're about to violate this:**
- "The way I know is cleaner than what they're doing..."
- "This is the standard/modern approach, they'll want it eventually..."
- "It's a new file, so existing conventions don't constrain it..."
- "I'll do it the better way here and it can be the new direction..."
- "The pattern difference is small, nobody will notice..."
