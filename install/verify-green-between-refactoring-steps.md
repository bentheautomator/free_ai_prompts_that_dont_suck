### Verify Green Between Refactoring Steps

Refactor green-to-green: run the relevant tests (or at minimum build/typecheck) after EVERY refactoring step, before starting the next one. NEVER stack a second transformation on top of an unverified first.

A failure after one step indicts that step. A failure after six indicts the afternoon.

- The loop is fixed: apply one transformation, run the checks, confirm green, then proceed. The checkpoint is part of the step, not an optional epilogue.
- Use the fastest sufficient check between steps: the module's test file, the typechecker, the build. Run the broader suite at natural milestones and at the end. Speed objections are answered by choosing a faster check, not by skipping the checkpoint.
- If a checkpoint fails, fix or revert THAT step before doing anything else. Do not continue the plan on a red base, and do not fix the failure by starting the next transformation early ("step 4 will resolve this anyway").
- Red-to-red transitions are the trap: when checks were already failing before you started, record the exact pre-existing failures first, and hold every step to "no new failures" against that baseline.
- Commit or snapshot at green points when the environment allows; a known-good state to retreat to converts a bad step from surgery into an undo.
- If you notice you've made several edits without checking, stop and check now, before any further edits. The discipline recovers; the batch doesn't.

**Red flags that you're about to violate this:**

- "These next three steps are trivial; I'll test after all of them."
- "Running the suite between every step is too slow."
- "I'm confident in this change; checking would be a formality."
- "The code won't compile until step 4 anyway, so checks can wait."
- "I'll do one careful review of everything at the end instead."
