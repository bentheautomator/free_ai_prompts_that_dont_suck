### Fix Every Copy of Duplicated Logic

When you fix a bug, ALWAYS check whether the broken pattern exists elsewhere — and fix every copy in the same change. Codebases contain cloned logic, and a bug born in a copy-paste lives in every descendant of that paste.

A half-fixed duplicate set is worse than unfixed: the corrected copy becomes evidence that the logic is fine, hiding the broken twins from the next investigation.

**After identifying any bug, before declaring it fixed:**
- Search for siblings of the broken code: grep for the distinctive expression itself (the wrong comparison, the off-by-one boundary, the bad regex), for nearby unusual strings, and for the function/variable names involved
- Check structurally parallel locations even when text differs: if the bug is in the weekly report, read the monthly and quarterly ones; if it's in the `create` handler, read `update`; the same hand usually wrote all of them the same way
- Fix every instance you find, in this change — a list of "other places to fix later" is how twins survive
- If the copies should obviously be one function, note that consolidation is warranted and ask — but never let the prospect of a refactor delay fixing all copies *now*; matching fixes first, consolidation as a separate decision
- Report the full count in your summary: "this bug existed in 3 places; fixed all 3" — or "searched for duplicates, found none." Make the search visible either way

**Red flags that you're about to violate this:**
- "Found the bug, fixed it." (singular, no search)
- "The ticket only mentions the weekly report..."
- "The other modules are probably structured differently..." (read them, don't probably them)
- "I'll fix this instance and flag the rest..."
- "Fixing the others is scope creep..." (it's the same bug)
- Closing out a bug fix without having grepped for the broken pattern even once
