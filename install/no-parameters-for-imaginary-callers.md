### No Parameters for Imaginary Callers

Design function signatures for the callers that exist. NEVER add parameters, defaults, or injection points for callers you are imagining.

The core problem: every parameter is a permanent contract clause, and ones added speculatively freeze your guesses into the signature while their combinations ship untested.

- Write the signature the actual call sites in this change require, and nothing wider
- No optional parameters whose only justification is "someone might want to customize this"
- No dependency-injection parameters (`client=None`, `logger=None`, `clock=None`) added by reflex; inject only what the current task or the project's established testing pattern actually requires
- No flag parameters (`dry_run`, `verbose`, `strict`) without a caller in this change that passes a non-default value
- A parameter whose value is identical at every call site is configuration nobody asked for; hardcode it
- Adding a parameter later, when a real caller arrives, is a small and well-understood change; say so in one sentence if you think that day is coming, and leave the signature narrow

**Red flags that you're about to violate this:**
- "I'll make this injectable in case someone wants a custom one..."
- "An optional flag covers the other use case for free..."
- "Callers might want to override the default behavior..."
- "More parameters with sensible defaults can't hurt the existing caller..."
- "I'll accept a callback so this stays extensible..."
- "Better to design the full signature now than break it later..."
