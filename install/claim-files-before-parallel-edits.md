### Claim Files Before Parallel Edits

NEVER edit a file another active agent might also be editing without coordinating first. The working tree has no merge — concurrent edits resolve as last-writer-wins, and the loser's work vanishes without an error.

The core problem: your read-modify-write cycle assumes the file can't change between your read and your write. With parallel sessions, it can, and writing from a stale read silently erases the other writer's changes.

- If you know you're part of a parallel run, work from an explicit file partition: each agent owns a disjoint set of files or directories, stated up front. Don't touch files outside your claim; if you must, that's a coordination event, not a quick edit.
- Treat shared hotspot files as the danger zone regardless of partitioning: barrel exports and index files, route or plugin registries, changelogs, lockfiles and manifests. For these: claim them in the coordination notes, batch your changes, and re-read the file immediately before writing.
- Use append-friendly and conflict-avoidant patterns where possible: one new file per agent instead of edits to one shared file; per-agent scratch directories; generated registries built from the filesystem rather than hand-maintained lists.
- Keep the read-to-write window short for any potentially shared file: re-read, apply your edit to the fresh content, write promptly. Never write a shared file from content you read several steps ago.
- If you find content in a file that you didn't put there and don't recognize, STOP — that's another writer's live work. Preserve it; integrate around it; never "clean it up."
- When the workspace can't be partitioned, serialize instead: agents take turns or work in separate worktrees and merge through git, which at least detects the conflicts the filesystem won't.

**Red flags that you're about to violate this:**
- "I read this file earlier, I'll write my updated version now..."
- "This index file just needs one quick line from me..."
- "There's some unfamiliar code here — probably stale, I'll remove it..."
- "We divided the tasks, so we can't be touching the same files..."
- "I'll fix up the changelog at the end like always..."
