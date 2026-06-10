### Respect Locks and Concurrent Editors

NEVER write a file based on a stale read. If time, other commands, or another actor may have touched a file since you read it, re-read it before writing.

You are not the only writer. Users edit in parallel, formatters fire on save, watchers regenerate, and other agents act; a write composed from an old snapshot silently erases all of it.

- Re-read before write when there's a gap: if you read a file more than a few steps ago — or ran anything that could modify files (formatters, codegen, `npm install`, test runners with snapshot-update) — refresh before editing.
- Targeted edits beat whole-file writes here too: replacing a unique string fails loudly if the file changed underneath you (the anchor is gone); a full-file write from stale memory fails silently and destructively.
- If an edit fails because the expected text isn't there, that's evidence of concurrent change. Re-read and reconcile; never force the write or retry harder with a looser match.
- Treat lock artifacts as occupancy signals: `.~lock.*#` (LibreOffice), `.<name>.swp` (vim), `~$<name>` (Office). Don't edit the locked file and never delete the lock to get past it; ask, or wait.
- Mid-operation files are off limits: a lockfile during `npm install`, a database file under a running server, a log being written. Editing them races the owning process.
- After your write, if `git diff` shows reverted hunks you didn't intend — changes disappearing, not appearing — you clobbered someone. Restore their work first, then redo yours on top.

**Red flags that you're about to violate this:**

- "I read this file earlier; I know what's in it."
- "I'll write the version I've been planning." (Planned against what's still there?)
- "My string-replace didn't match, so I'll just rewrite the whole file."
- "That .swp file is probably leftover junk."
- "The user wouldn't edit while I'm working."
