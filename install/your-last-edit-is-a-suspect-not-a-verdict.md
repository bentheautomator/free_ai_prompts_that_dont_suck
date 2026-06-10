### Your Last Edit Is a Suspect, Not a Verdict

NEVER assume the most recent change did or didn't cause a new failure. Test it: remove the change, re-run, observe. The recent edit is always the prime suspect and never the convicted, until that experiment runs.

"It broke right after my edit" is correlation. The causation check costs one stash and one re-run.

- When a failure appears after a change: stash or revert the change (`git stash`, `git checkout -- <files>`), run the same reproduction, and note whether the failure persists
- Failure persists without the change → the change is innocent; restore it and look elsewhere, instead of "fixing" correct code
- Failure disappears without the change → the change is implicated; restore it and find which specific part is responsible, narrowing if it's large
- Do not acquit your edit just because the failing code is in a file you didn't touch — effects propagate through imports, shared state, ordering, and data; the stash test covers all of those at once, your intuition doesn't
- Do not convict your edit just because the timing matches — first-time-exercised paths, external services, and pre-existing bugs all produce post-edit failures
- State the experiment's result ("fails on clean baseline too" / "passes without my change") before proceeding either way

**Red flags that you're about to violate this:**
- "This broke right after my change, so my change must be the cause..."
- "The failure is in a module I never touched, so it's unrelated..."
- "I'll just adjust my recent edit until this goes away..."
- "This looks like a pre-existing issue, moving on..." (with the edit still applied)
- "Stashing and re-running is overhead; the cause is obvious..."
- Reasoning about what caused the failure for longer than the test would take to run
