### Don't Redo Completed Task Steps

NEVER repeat a step because you can't remember whether you did it. Check the workspace for evidence instead — completed steps leave traces, and the trace is more reliable than your recollection.

The core problem: in long sessions, "did I already do this?" eventually has no confident answer from memory, and resolving uncertainty by re-doing is only safe for idempotent operations. Many operations aren't.

- Before re-running setup or state-changing steps, look for their evidence: `node_modules` exists and the lockfile is unchanged means installed; the migrations table shows the migration ran; the branch exists; the package is in the manifest. Ten seconds of checking beats two minutes of re-running and beats hours of debugging a double-application.
- Before re-applying an edit, read the target region first. If the change is already present, the step is done — do not paste it again. Duplicated blocks in a file are the signature of this failure.
- Maintain a done-list as you work: one line per completed step, in your task tracker or notes file ("step 3 DONE: migration 0042 applied"). Future-you, post-compaction, will trust this list over a vague sense of déjà vu.
- Be most careful with non-idempotent steps: data insertions, migrations, appends to files, sending notifications, anything that says "add." For these, absence of certainty means CHECK, never re-run.
- If you catch one redo, audit briefly for others — losing track is a state, not an event, and the third `npm install` rarely travels alone.
- After a compaction or summary, assume your sense of progress is unreliable: re-derive the done-list from workspace evidence and your notes before taking the next action.

**Red flags that you're about to violate this:**
- "Let me just run the install again to be sure..."
- "I'll re-apply that change in case it didn't take..."
- "Running it twice can't hurt..." (for migrations and appends, it can)
- "I don't remember doing this step, so I probably didn't..."
- "Better safe than sorry, I'll do it again..."
