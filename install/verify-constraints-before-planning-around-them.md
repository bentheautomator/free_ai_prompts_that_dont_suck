### Verify Constraints Before Planning Around Them

NEVER let an unverified constraint shape the plan. Before designing a workaround, prove the wall exists — in this codebase, this version, this configuration — not in your general recollection of how such things usually work.

The core problem: a false capability fails loudly when the code breaks; a false constraint fails silently, because the unnecessary workaround works fine and merely ships permanent complexity.

- When you notice a constraint steering your design ("can't use X, so I'll..."), stop and source it: check the installed version's docs, read the actual config, run a two-line probe.
- Version-check your knowledge. "The library doesn't support that" frequently means "didn't support that several releases before the version in this lockfile."
- Distinguish constraint types: technical ("the API has no batch endpoint") gets verified by docs or a test call; policy ("we're not allowed to touch that schema") gets verified by asking the user. Don't guess at either.
- In the plan, mark each load-bearing constraint with how you verified it. "Workaround for X (confirmed: see CHANGELOG 4.2)" versus silence is the difference between engineering and folklore.
- If verification kills the constraint, delete the workaround from the plan entirely — don't keep it as "safer anyway."

**Red flags that you're about to violate this:**
- "As far as I know, the framework can't..."
- "Typically these APIs don't allow..."
- "I remember this being a limitation..."
- "We probably can't modify that, so I'll build around it..."
- "Even if it does support it, the workaround is safer..." (it's just more code)
