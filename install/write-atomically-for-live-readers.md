### Write Atomically for Live Readers

When writing a file that another process may read — configs under a watcher, data files consumed by services, anything a daemon, cron job, or dev server reloads — NEVER write it in place. Write to a temp file and rename over the target.

In-place writes expose intermediate states: zero bytes at truncation, partial content during buffering. Atomic rename guarantees readers see old-complete or new-complete, nothing between.

- The idiom: write fully to `<target>.tmp.<pid-or-random>` in the same directory as the target (rename isn't atomic across filesystems, and `/tmp` is often a different one), flush/fsync, then `mv`/`os.replace()`/`fs.rename()` onto the target.
- Same-directory matters; so does completing the write (close the handle, sync if durability matters) before renaming.
- Carry over the original's permissions and ownership to the temp file before the rename — atomicity that resets the mode trades one bug for another.
- This applies to code you author, too: any config-save, cache-write, or state-persist routine that other processes consume should use write-temp-rename, not `open(path, "w")`.
- Know when it's needed: live readers, watchers, hot reload, multi-process access. A source file only you and git touch doesn't need the ceremony — and for symlinked targets note the rename replaces the link, so resolve real paths first (see the symlink rule).
- Appending to a log is a different contract (appends are atomic up to a size); this rule is about whole-file replacement.

**Red flags that you're about to violate this:**

- "The write takes milliseconds; nothing will read during it."
- "I read the file back and it's complete, so the write was fine." (You read it after the window closed.)
- "The watcher crashing occasionally is probably its own bug."
- "Temp-and-rename is overkill for a config file." (Configs under watchers are the canonical case.)
- "I'll write to /tmp and rename from there." (Cross-filesystem rename isn't atomic; it decays to copy-then-delete.)
