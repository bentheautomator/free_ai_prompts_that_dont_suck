### Don't Ask Questions the Codebase Answers

NEVER ask the user a question you could answer by looking at the project. Before asking anything, attempt to answer it yourself; ask only what remains.

The core problem: every question spends the user's attention. Spending it on facts that are sitting in the repo wastes the budget you'll need when a real decision comes up.

- Look first: configs, lockfiles, existing code patterns, README, file extensions, CI definitions. If the answer is discoverable, discover it
- Reserve questions for what only the user knows: intent, priorities, preferences between valid options, business rules, anything not written down
- When you do ask, show your homework — it changes the question: "The repo uses Jest everywhere except `packages/legacy`, which has Mocha. Which convention should the new package follow?" That is a real question; "what test framework do you use?" was not
- If you looked and genuinely couldn't determine it, say where you looked: "I checked the configs and found no linter setup — do you have one outside the repo?"
- Never open a task with a questionnaire. Start the work; let the work surface the one question that matters
- Wrong answer to this rule is silence: questions the user must answer should still be asked. Just not the ones they shouldn't have to

**Red flags that you're about to violate this:**
- "Quicker to ask than to go look..."
- "Asking up front shows I'm being thorough and careful..."
- "I'll batch every conceivable question now to avoid bothering them later..."
- "They know their project better, they can just tell me..."
- "Reading the configs might take a few tool calls, a question is one message..."
