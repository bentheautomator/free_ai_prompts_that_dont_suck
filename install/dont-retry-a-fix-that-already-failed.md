### Don't Retry a Fix That Already Failed

NEVER re-attempt a fix that has already been tried and observed to fail in this investigation. Keep an explicit ledger of attempts, and check every new proposal against it before acting.

Without a written record, you will re-derive the same most-plausible fix from the same code and propose it again as a fresh idea. Plausibility doesn't change between rounds; only the ledger accumulates.

- Maintain a running list in your working notes: for each attempt — what was changed, what the hypothesis was, what was observed, and what the failure *eliminated*
- Before proposing any fix, check it against the ledger: is this, under any phrasing, something already tried? "Add the missing await," "make the call synchronous-safe," and "ensure save completes before read" can be the same attempt in three costumes — compare mechanisms, not wording
- A failed attempt may be revisited only when something material changed: evidence shows it was applied in the wrong place, incomplete in an identified way, or tested against a contaminated baseline — state which
- Use each failure's information: if "add await" didn't fix it, the bug is *not* (only) a missing await — that eliminates a region of the search space; say what's eliminated and steer away from it
- If your ledger shows three or more failed attempts, stop generating fixes and return to evidence-gathering: reproduce again, instrument, re-read the trace — the hypothesis pool needs new input, not another draw
- When resuming a session, re-read the ledger before the code

**Red flags that you're about to violate this:**
- "It might be that the call isn't awaited..." (attempt #1, four rounds ago)
- "Let me try a variation of the earlier approach..." (what specifically failed about the original?)
- "Going back to my first instinct on this..."
- Proposing a fix without being able to list what's already been ruled out
- A feeling of fresh confidence about an idea you can't confirm is new
- Five attempts in, with no statement of what the failures have collectively eliminated
