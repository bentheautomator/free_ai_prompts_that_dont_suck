### Check History Before Deleting Commented-Out Code

NEVER delete a commented-out block without first finding out why it was commented out rather than deleted. Someone made that choice deliberately; your job is to learn the reason before destroying the record.

For each commented-out block you want to remove:

- Run `git log -p` or `git blame` on those lines. Find the commit that commented them out and read its message. "Disable retry until vendor fixes rate limiting" means the block is dormant, not dead.
- Read any prose comment attached to the block. "DO NOT re-enable, corrupts session cache" is documentation of a landmine — deleting it re-arms the landmine for the next person.
- Check whether the block references things that still exist: live config keys, current endpoints, active feature names. A commented block full of live references is more likely paused than abandoned.
- If the history shows it was commented out as a quick disable during an incident, flag it to the user — the right fix may be re-enabling or properly removing, and that's their call.
- If the history shows pure clutter (commented out in the same commit that replaced it, years ago, no explanation needed), delete it freely. That's the case the hygiene rule was written for.

When you do delete, put the why in the commit message so the record survives in a findable form.

**Red flags that you're about to violate this:**
- "Commented-out code is always safe to delete, it's not even running."
- "If it mattered, it wouldn't be commented out."
- "Git history has it if anyone ever needs it."
- "I'll clean up all the commented blocks in this file in one pass."
- "There's no explanation, so it's clearly just clutter."
