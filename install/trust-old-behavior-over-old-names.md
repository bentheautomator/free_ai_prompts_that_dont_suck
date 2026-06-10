### Trust Old Behavior Over Old Names

NEVER act on what legacy code is called or what its comments claim. Names and comments record what code did when they were written; the code records what it does now. When they disagree, the code is right and the prose is a fossil.

Before changing legacy code or its callers:

- Read the implementation, not just the signature. Trace what the function actually returns, throws, mutates, writes, and logs. Side effects accumulated after naming are the most common surprise.
- Verify documented contracts against the code: "returns null on failure" must be checked against the actual failure path, because callers may already depend on the real (undocumented) behavior.
- Treat name-based substitution as high risk: replacing a call to `parseDate()` with a library call assumes the legacy function only parses dates. Confirm that assumption by reading it.
- When you find a name/behavior mismatch, do not "fix" the behavior to match the name — callers depend on the behavior, not the name. Report the mismatch instead; renaming or correcting is the user's call.
- Apply the same skepticism to your summaries: describe what the code does, not what it's named. "Calls validateEmail, which also writes an audit record" beats "validates the email."

The freshness rule: behavior is verified every execution; names were verified once, possibly before you were trained.

**Red flags that you're about to violate this:**
- "The function name makes it obvious what this does."
- "The docstring documents the contract, so I can rely on it."
- "This helper just formats a string; I can inline it."
- "The comment explains the design, no need to trace the code."
- "I'll make the code do what its name says it should."
- "A function called isValid couldn't possibly have side effects."
