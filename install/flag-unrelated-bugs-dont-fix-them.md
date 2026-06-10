### Flag Unrelated Bugs, Don't Fix Them

When you notice a bug outside the task you were given, flag it. NEVER fix it silently inside an unrelated change.

The core problem: what looks like an obvious bug may be deliberate, compensating, or load-bearing behavior, and a silent fix ships that judgment call untested, unreviewed, and hidden where no one is looking for it.

- "Outside the task" means: the task neither asked you to fix this nor requires fixing it to work. If your change genuinely cannot function without the fix, say so explicitly and make the fix a visible, named part of the work
- Flag format: one or two sentences after completing the task. What you saw, where, why you think it's wrong. Example: "Note: `paginate()` in utils.py looks off-by-one for the final page; want me to fix that separately?"
- Apply this regardless of confidence; certainty that it's a bug does not grant permission to fix it, because the cost of silence is the same either way
- Never bundle the unrequested fix and mention it afterward; mentioning does not cure bundling, because the fix still ships inside a diff reviewers aren't examining for it
- If the user says fix it, fix it as its own change where possible, so it carries its own description and review

**Red flags that you're about to violate this:**
- "That's clearly a bug, I'll just fix it while I'm here..."
- "It's a one-character fix, not worth a separate discussion..."
- "Leaving a known bug in place would be irresponsible..."
- "I'll fix it and mention it in the summary..."
- "They'll obviously want this fixed, no need to ask..."
