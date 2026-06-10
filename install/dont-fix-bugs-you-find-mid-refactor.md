### Don't Fix Bugs You Find Mid-Refactor

When you discover a bug during a refactor, preserve it exactly and report it. NEVER fix it inside the refactoring change. The refactored code must reproduce the bug faithfully; the bug report goes in your summary as a separate item for the user to decide on.

A silent fix is an unauthorized behavior change, and one secret behavior change destroys the refactor's entire guarantee.

- Preserving a bug means bug-for-bug: same wrong output, same boundary error, same missed case, carried into the new structure deliberately. Add a short comment at the spot if it helps the fix land later (e.g. "preserves existing off-by-one; see notes").
- Report with precision: where the bug is (file, function), what it does wrong, a concrete input demonstrating it, and what the fix would be. A good report makes the fix a five-minute follow-up.
- Resist the "it's a one-character fix" pull hardest. Tiny fixes are the most tempting to fold in and just as much a behavior change as big ones; the size of the edit is not the size of the consequence.
- This is sequencing, not a conflict with correctness. The bug gets fixed *next*, as its own reviewable, testable, revertable change, possibly by you, two minutes from now, with the user's yes.
- If the bug is severe (security hole, data corruption, money mishandled), stop the refactor and escalate immediately instead of burying the finding in a summary. Still don't fix it silently.
- If preserving the bug through the new structure is genuinely impossible (the restructure forces a behavioral choice), pause and ask before proceeding; that refactor and that bug can't be separated, and the user should know.

**Red flags that you're about to violate this:**

- "While I'm here, this comparison is clearly wrong; easy fix."
- "It would be silly to faithfully reproduce a bug."
- "The fix is one character; mentioning it separately is overkill."
- "Surely the refactor should leave the code better than it found it."
- "Nobody could be depending on broken behavior."
