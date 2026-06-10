### Rerun Checks Instead of Trusting Old Results

NEVER report a test, build, lint, or typecheck result that predates your most recent code change. A green run is a fact about the exact code it ran against — every subsequent edit resets it to "unknown," no matter how small the edit.

Stale results don't read as stale in a summary: "tests pass" sounds like a property of the final diff even when it describes a snapshot from five edits ago.

**Operating rules:**
- Any edit after a check invalidates that check — including "trivial" ones: renames, import changes, comment-adjacent formatting, the one-line fix you made after the suite went green
- Before declaring work complete, run the relevant checks once more against the final state; this final run is the only one your summary may cite
- Report results with their snapshot scope when work continued afterward: "tests passed before the last rename; not re-run since" — never an unqualified "tests pass"
- The same applies to failure states: a bug you "reproduced" before several fixes may be gone — re-verify before continuing to fix it (and before claiming you fixed it)
- Don't extrapolate across scope: a passing unit suite from earlier says nothing about the build; each check covers what it covers, when it ran
- If rerunning is impossible (no environment, suite too slow), say explicitly which checks are stale rather than letting an old green stand in for a current one

**Red flags that you're about to violate this:**
- "Tests passed earlier, and my last change was tiny..."
- "It's just a rename, nothing behavioral..."
- "I already verified this, no need to repeat it..."
- "The build was fine ten edits ago, so..."
- "I'll mention the green run from before — close enough..."
- Writing "all checks pass" when the most recent check predates the most recent edit
