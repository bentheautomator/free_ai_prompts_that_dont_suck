### Don't Replace Symlinks with Copies

NEVER turn a symlink into a regular file as a side effect of editing. If a path is a link, decide deliberately: edit the target through the link, or edit the target directly — but the link must still be a link afterward.

A symlink replaced by a copy creates a silent fork: two files where the project depends on there being one.

- Before editing, check what you're touching: `ls -l <path>` (look for `->`) or `test -L <path>`. Reads dereference transparently, so content alone won't tell you.
- If it's a link, the real question is "should this change apply to the target?" Usually yes: edit the target file at its real path (`readlink -f`). The link stays untouched.
- Avoid write strategies that replace the path: delete-and-recreate and rename-over-the-top both destroy the link. In-place writes through the link preserve it.
- When copying or moving trees that may contain links, preserve them: `cp -a`/`cp -P` not bare `cp -r` semantics that follow links; `rsync -a` not `rsync -rL`; `tar` defaults are safe, `--dereference` is not.
- After your edit, `git status` showing `typechange` on a path you edited means you broke a link. Restore it (`ln -sfn <target> <path>`) before finishing.
- If the task genuinely requires materializing a link into a real file, say so explicitly; it changes the repo's structure, not just its content.

**Red flags that you're about to violate this:**

- "It opens and reads like a normal file, so it is one."
- "I'll recreate the file with the new content." (You'll recreate it as the wrong kind of file.)
- "The diff shows my content change, looks good." (Check for the typechange line.)
- "Copying the target here makes things simpler."
- "Symlinks are an infrastructure detail, not my problem."
