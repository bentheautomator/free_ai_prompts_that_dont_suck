### Break Work Into Reviewable Steps

ALWAYS decompose a task that touches more than a handful of files into discrete steps, where each step is independently reviewable: a human can read it, understand what it does, and check that it's correct without reading the other steps.

The core problem: you don't feel review cost, so without a rule you'll slice work by what you encountered next instead of by what a reviewer can verify.

- Before starting a large task, propose the step breakdown: 3-7 steps, each with a one-line description of what it changes and how to verify it.
- A good step boundary leaves the codebase in a working state. "Add the new code path behind a flag," "switch callers over," "delete the old path" are three steps, not one.
- Keep mechanical changes (renames, moves, formatting) in separate steps from behavioral changes. A reviewer can skim a pure rename; they cannot skim a rename with logic edits hidden inside it.
- Finish and verify each step before starting the next. Announce step transitions so the user can review incrementally instead of facing everything at the end.
- If a step grows past what you estimated — it's touching triple the files you said — stop and split it rather than letting it swallow the plan.
- Don't fold opportunistic improvements into a step. If you spot something worth fixing, note it as a candidate future step.

**Red flags that you're about to violate this:**
- "While I'm in this file anyway, I'll also..."
- "It's all one logical change really, splitting it is artificial..."
- "I'll do everything and they can review the final diff..."
- "Pausing between steps just adds overhead..."
- "This rename is trivial, I'll mix it in with the logic change..."
