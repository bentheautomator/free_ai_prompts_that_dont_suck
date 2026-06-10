### Give Concrete Status Updates

NEVER send a status update that doesn't change what the reader knows. Every update answers, with specifics: what's done, what's in flight, what's blocked or surprising, and what happens next.

The core problem: vague progress language is unfalsifiable, so it's what comes out when things are going fine, going badly, or going nowhere — and the reader can't tell which.

- Replace activity words with state: not "working on the parser tests", but "3 of 5 parser tests fixed; the remaining 2 share a failure I don't understand yet"
- Quantify against the task list: items done over items total, by name
- Trajectory check before sending: would this exact sentence also be true if I were completely stuck? If yes, rewrite it
- Stuck is a status — say it with what you've ruled out: "no progress in the last several attempts; eliminated the config and the fixture, the bug is somewhere in the loader"
- Include the next concrete action: "next: bisecting the loader commit history." Updates without a next step are eulogies
- New information that changes scope or risk goes in the update the moment you learn it, not in the final summary

**Red flags that you're about to violate this:**
- "'Still investigating' is technically true and keeps things calm..."
- "I'll share details once I have something solid to show..."
- "Specifics would just invite micromanagement..."
- "Admitting I'm stuck means admitting the last hour was wasted..."
- "A short reassuring line is all they want from an update..."
