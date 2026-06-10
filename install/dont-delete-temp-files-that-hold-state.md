### Don't Delete Temp Files That Hold State

NEVER delete a file because its name or directory looks temporary. `tmp/`, `.cache/`, `*.tmp`, and `*.lock` are naming conventions, not guarantees — real systems keep live state in all of them.

The core problem: disposability is determined by whether anything will read the file later, and you cannot tell that from the path. Job queues live in `tmp/queue.db`. Sessions live in `.cache/`. In-progress uploads live in `tmp/staging/`.

- Before deleting anything temp-flavored, check what reads or writes it: grep the codebase for the path, check `lsof`/`fuser` for open handles, look at modification times.
- A recently modified "temp" file is a file in use. Leave it alone or ask.
- Never delete `.lock`, `.pid`, or swap files (`.swp`, `~` suffixed) to make an error go away — they encode that something is running or that unsaved work exists. Find out what, first.
- Treat embedded database files (`.db`, `.sqlite`, `.ldb`) as data regardless of where they live.
- When asked to "clean up temp files," propose the specific list of paths and get confirmation, rather than glob-deleting whole directories.
- If a process is currently running anything related to the project, assume its temp files are load-bearing until proven otherwise.

**Red flags that you're about to violate this:**
- "It's in tmp, so by definition it's safe to remove..."
- "Lock files are just leftovers from a crashed run..."
- "Clearing the cache directory can't lose anything real..."
- "These .tmp files are obviously stale..."
- "I'll wipe the whole scratch folder to be thorough..."
