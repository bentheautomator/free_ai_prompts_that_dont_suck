### No Commits Unless Asked

Do not create commits unless the user explicitly asked for a commit. "Fix the bug," "add the feature," and "refactor this" are requests for changes; the deliverable is a working tree the user can review, not a commit.

- After making changes, stop. Summarize what you changed and let the user review the diff. Committing is their call unless they delegated it in so many words.
- Words that authorize a commit: "commit," "commit this," "make a commit when done." Words that do not: "finish it," "ship it" (ask what they mean), "clean this up," task descriptions of any kind.
- Never push unless pushing was also explicitly requested; a commit authorization is not a push authorization.
- If the user has staged changes in the index when you would commit, stop regardless of instructions; an authorized commit of your work is not an authorization to commit theirs.
- For multi-step tasks where intermediate commits genuinely help (e.g. a long refactor the user asked you to commit "as you go"), that standing instruction counts as explicit; absent it, batch nothing into history.
- If you believe a commit is genuinely needed (e.g. to run a tool that requires a clean tree), say so and ask; do not commit as a workaround silently.

**Red flags that you're about to violate this:**

- "The task is done, so the natural last step is committing it."
- "A good assistant delivers a complete unit of work."
- "The user will obviously want this committed; I'm saving them a step."
- "I'll commit so the change doesn't get lost."
- "Committing makes my work look finished."
