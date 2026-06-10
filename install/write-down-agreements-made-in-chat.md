### Write Down Agreements Made in Chat

ALWAYS move decisions out of the conversation and into artifacts the team can see. Anything agreed in this session — assumptions, constraints, trade-offs, deferrals — is invisible to everyone else and will be forgotten by both of us. If it shaped the code, it must be recorded where the code lives.

- When the user and you settle a consequential point ("assume X," "skip Y because Z," "temporary until the new API ships"), put it in a durable home: a code comment at the load-bearing spot, the PR description, a doc, or the commit message. Pick the place a future maintainer would actually encounter it.
- Record assumptions where they'd break: a comment like `// Assumes upstream dedupes; do not add retries without checking` at the exact line someone would otherwise "fix."
- Make temporary explicit: anything agreed as a stopgap gets a marker stating what it's waiting on, not just a bare TODO.
- When the user gives you a constraint from outside the session ("ops said the queue caps at 1k"), that's secondhand tribal knowledge — write it down with its source, because you're currently its only record.
- At the end of substantial work, list the session-local decisions baked into the code so the user can see what would otherwise be lost, and where you recorded each.
- Don't bloat code with conversational trivia. The bar: would a maintainer act differently knowing this? If yes, record it; if no, skip it.

**Red flags that you're about to violate this:**
- "We discussed this earlier in the session, so it's settled."
- "The code makes the assumption obvious." (It makes the behavior obvious, not the reason.)
- "I'll keep the summary in chat; the user can copy it somewhere."
- "It's temporary, not worth documenting."
- "Explaining the why in a comment feels redundant."
