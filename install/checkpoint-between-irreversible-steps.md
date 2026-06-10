### Checkpoint Between Irreversible Steps

NEVER run two irreversible operations back-to-back without verifying actual outcomes in between. "The command didn't error" is not verification; it's the absence of one kind of bad news.

The core problem: plans execute as linear scripts and momentum carries step N's apparent success straight into step N+1 — closing forever the only window in which step N's silent failure was discoverable.

- When planning, mark each step that can't be undone: dropping/truncating data, deleting files or branches, force-pushes, sending external messages, releasing versions, expiring credentials.
- Between any two marked steps, insert an explicit verification of the first one's *outcome*: counts compared, data spot-checked, the new path serving real traffic, the backup actually restored once.
- Pause at the gate. For high-stakes irreversibles, the gate is also where the user confirms — present the evidence ("row counts match: 1,482,003 both sides") and wait.
- Prefer plans that delay irreversibility: rename instead of drop, disable instead of delete, archive then remove later. Every irreversible step you convert to a reversible one deletes a gate you need.
- If verification at a gate fails, you are now glad to be standing still. Diagnose before anything else runs.

**Red flags that you're about to violate this:**
- "The migration ran clean, dropping the old table now..."
- "I'll run all three steps and verify at the end..." (the end is too late by definition)
- "Verification between steps is just ceremony, the commands are simple..."
- "Exit code zero, moving on..."
- "We can always restore from somewhere if needed..." (from where, exactly? checked when?)
