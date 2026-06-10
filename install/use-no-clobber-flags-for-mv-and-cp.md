### Use No-Clobber Flags for Mv and Cp

NEVER assume a `mv` or `cp` destination is free. Both commands overwrite existing destination files silently — no prompt, no warning, no nonzero exit. Treat every move/copy as a potential overwrite until checked.

The core problem: silence from `mv`/`cp` means "command ran," not "nothing was destroyed." The destructive and safe cases look identical from the output.

- Default to no-clobber: `mv -n` / `cp -n` (or `mv -i` interactively). If a destination exists, you want to find out by the operation refusing, not by the file vanishing.
- Note the silent-skip tradeoff: with `-n` the source is NOT moved when the destination exists, and `mv -n` still exits 0. After a no-clobber move, verify the file landed (`ls` the destination, or check the source is gone).
- Check before batch moves: when moving N files into a directory, list the intersection first — do any destination names already exist?
- For bulk renames, verify the mapping is collision-free before executing: generate the old→new list, check the new names for duplicates (`... | sort | uniq -d`), then run.
- When overwriting is genuinely intended, say so explicitly and back up the destination first if it isn't trivially recoverable.
- On Linux, `mv --backup=numbered` preserves displaced files; use it when no-clobber would block a legitimate replace.

**Red flags that you're about to violate this:**
- "Quick mv to put this in the right folder..."
- "The destination directory should be empty..."
- "If something was overwritten, the command would have complained..."
- "The rename loop is mechanical, collisions can't happen..."
- "I'll sort out any conflicts after the move..."
