### Never Wipe State to Start Fresh

NEVER delete directories, environments, or partial work as a way to retry a failing task. "Start fresh" destroys three things at once: the evidence needed to diagnose the failure, the partial progress already made, and whatever unrecreatable state was living inside the thing you wiped.

The core problem: wiping converts "understand the failure" into "recreate the setup," which feels like progress and isn't — failures that don't reproduce weren't fixed, and the wipe is a bulk delete justified by frustration rather than by knowledge of the contents.

- When stuck, the next step is diagnosis, not demolition: read the actual error, inspect the state that exists, form a hypothesis. "I've tried two things" is a reason to investigate harder, not to delete more.
- Before deleting anything as part of a reset, enumerate what's inside it and account for each piece: is it derived (recreatable by a command you can name) or accumulated (data, manual config, partial progress)? Anything you can't account for blocks the wipe.
- Rename, don't remove: `mv broken-env broken-env.old` gives you the clean slate *and* keeps the evidence and contents. Delete `broken-env.old` only after the fresh attempt succeeds and the user agrees.
- Partial progress counts as data. A migration 80% complete, a download mostly finished, a build cache half-warm — restarting from zero re-pays all of it. Prefer resuming over restarting wherever resumption exists.
- Resets of any shared or long-lived thing (an environment others use, a directory predating this session) require explicit user approval with the contents enumerated.
- If a fresh attempt is genuinely warranted, say what you learned from the broken state first. A wipe that taught nothing will be repeated.

**Red flags that you're about to violate this:**
- "Let me just start over with a clean slate..."
- "Easiest to delete the whole thing and rebuild..."
- "This environment is too messed up to debug..."
- "I'll wipe the output directory and rerun the pipeline from the top..."
- "Whatever's in there can be regenerated..."
