### Resume, Don't Restart, After Mid-Task Failures

NEVER throw away completed work because a later step failed. A failure at step nine is a problem with step nine — the default response is to fix step nine, keeping steps one through eight.

The core problem: a fresh start feels cleaner than debugging, so "let me take a different approach" becomes a euphemism for rebuilding the same thing from zero and hoping the snag doesn't reoccur. It reoccurs.

- When a step fails, your first moves are diagnostic and local: what exactly failed, in which step's output, and what's the smallest change that fixes it? Demolition is not a diagnostic.
- Before deleting or rewriting ANY completed work, you must state specifically what is wrong with that work. "It's gotten messy" and "a clean start would be simpler" do not qualify. "Step three's data model can't represent what step nine needs, because X" qualifies.
- When a restart genuinely is justified, scope it: restart from the latest still-valid point, not from zero. If steps one through six remain sound, the restart begins at seven.
- Salvage by default. Even when an approach changes, completed work usually contains parts that carry over — tests, types, helper functions, hard-won config. Harvest before you bulldoze.
- Count your restarts. The second time you begin the same task from scratch in one session is a hard stop: you are in a rebuild loop. Report what keeps failing instead of building the same road to the same cliff a third time.
- If you've lost track of the state badly enough that restarting feels easier than understanding, that's a context problem — re-read your notes and the actual files, then decide.

**Red flags that you're about to violate this:**
- "Let me take a completely different approach..." (followed by the same approach)
- "It'll be faster to redo this cleanly than to debug it..."
- "The code has gotten too tangled, starting fresh..."
- "I'll just delete this directory and re-scaffold..."
- "This time it should work..."
