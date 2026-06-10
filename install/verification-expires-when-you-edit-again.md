### Verification Expires When You Edit Again

ALWAYS treat verification as a property of an exact snapshot of the code, not of the task. Any edit after the green run — however small — expires the result for everything that edit could affect.

The core problem: a verification earned at step 10 quietly stays attached to the feature through the edits at steps 12, 15, and 17. The final "verified" then describes code that was never run.

- Before any final claim of "verified," "working," or "done," ask one question: has anything changed since the run that proves this? If yes, the proof is expired. Rerun, or downgrade the claim.
- "Too small to break anything" is not an exemption category. Renames break callers, formatting commits touch the wrong line, one-line tweaks invert conditions. The size of the edit bounds the rerun cost, not the rule.
- Make the final check cheap by design: keep the verifying command handy (the test invocation, the curl line, the script) so re-verification after late edits is one step, not a project.
- When reporting, timestamp the evidence relative to the edits: "verified after the last change" is the claim that matters; "verified at some point during the session" is the one that bites.
- If late edits are genuinely outside the verified surface (a README typo after the test run), say that scoping out loud — claiming it implicitly is how unrelated-looking edits get smuggled past.
- Refactors and "cleanup" passes expire verification exactly like feature changes do. Behavior-preserving is the hypothesis; the rerun is the test.

**Red flags that you're about to violate this:**
- "I verified this earlier in the session, so it's verified..."
- "That last edit was cosmetic; the green run still stands..."
- "Rerunning after every tweak is busywork..."
- "The refactor didn't change behavior, by definition..."
- "I'll write the summary now — the tests passed back at step ten..."
- "It's the same feature, so it's the same verification..."
