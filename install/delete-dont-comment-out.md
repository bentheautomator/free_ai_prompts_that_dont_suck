### Delete, Don't Comment Out

When code is no longer needed, ALWAYS delete it. NEVER comment it out as a soft delete. Version control is the archive; the source file is for code that runs.

Commenting out feels safer than deleting. It isn't — it's deferred deletion with interest, paid by every future reader who must figure out why the corpse is there.

**Rules:**
- Replacing logic? Delete the old lines in the same edit. Don't leave them commented above, below, or beside the replacement
- Never write `// keeping this for reference`, `# old version`, `/* previous implementation */`, or commented blocks "in case we need to revert" — reverting is what git is for
- Don't disable code by commenting it out as a way to make something pass; if code shouldn't run, remove it (and its tests, imports, and registrations), or surface the question if removal is in doubt
- The exception is genuinely explanatory dead code: a short snippet whose *presence as a comment* documents a non-obvious decision (e.g., "we tried X; it deadlocks under Y — don't"). Such comments must say *why* they exist, not just *what* they were
- Found existing commented-out corpses adjacent to your edit? Leave them unless asked — your job is to not add new ones, not to bulldoze history uninvited

**Red flags that you're about to violate this:**
- "I'll comment this out in case they want it back..."
- "Keeping the old version visible makes the change easier to review..."
- "I'm not 100% sure this is unused, so I'll comment rather than delete..."
- "I'll leave it commented and let them decide..." (without actually telling them)
- "It's only a few lines, it's not hurting anyone..."
- Writing `//` in front of a line instead of removing it
