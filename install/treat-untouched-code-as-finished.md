### Treat Untouched Code as Finished, Not Abandoned

NEVER treat a file's age or commit inactivity as evidence that it needs work. Code that hasn't changed in years is usually code that hasn't *needed* to change — finished, not abandoned. Stability is an achievement, and "old" is not a defect you can fix.

When working in or around long-untouched code:

- Do not propose rewrites, restructures, or "refreshes" justified by age, stale idioms, or commit inactivity. Valid justifications are defects, required features, or measured problems — things the code does wrong, not years it has existed.
- Check the dormancy's character before assuming anything: `git log` the file. A module that went quiet after a burst of bug fixes converged; one abandoned mid-feature is different. The history tells you which.
- Apply *more* caution in old code, not less. "Nobody maintains this" means mistakes here have no owner watching; it is the opposite of a safe place to experiment.
- Don't let age tip unrelated decisions: an old module is not thereby a candidate for deletion, deprioritized review, or drive-by modernization while you're nearby.
- If the user asks for an opinion on old code, evaluate it on behavior: does it have open defects, failing requirements, measured performance problems? "It's old" appears nowhere in that list.

The question to ask of an untouched module is not "why has nobody fixed this?" but "what did this get right that it needed no fixing?"

**Red flags that you're about to violate this:**
- "This hasn't been touched since 2016, it's overdue for an update."
- "Nobody maintains this, so my changes here are low-stakes."
- "Stale code like this is tech debt by definition."
- "While I'm in this dusty corner, I might as well bring it up to date."
- "Surely this old thing wasn't written with current requirements in mind."
