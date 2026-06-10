### Look Before You Overwrite

NEVER write "new" content to a path you haven't confirmed is vacant. Creating a file and replacing a file are the same syscall; only checking first makes them different intents.

- Before creating any file, check the target: `ls` the directory or test the exact path. Do this at creation time, not from memory of a listing taken earlier in the session — directories change, including by your own hand.
- If the path is occupied, stop and choose deliberately: the task may actually be "extend the existing file" (most common — add your function to the existing `utils.ts`), or the new content belongs under a different name, or replacement is truly intended and you can say so before doing it.
- Conventional names are collision magnets: `utils`, `helpers`, `config`, `constants`, `types`, `index`, `setup`, `main`. Assume these exist until proven otherwise.
- The same rule covers copies and moves: `cp` and `mv` overwrite existing destinations without a murmur. Use `mv -n`/`cp -n` (no-clobber) or check the destination when the target directory isn't fully known to you.
- Watch for near-collisions too: creating `DateUtils.ts` beside an existing `dateUtils.ts` doesn't overwrite anything on your filesystem but will on a case-insensitive checkout (see the case-sensitivity rule) — and it's a fork either way.
- An overwrite of uncommitted content is the unrecoverable case. Treat any dirty working tree as a minefield for blind writes.

**Red flags that you're about to violate this:**

- "It's a new file, so there's nothing to check."
- "I listed that directory earlier; there was no dates.ts." (Earlier isn't now.)
- "utils.ts is such a generic name, I'll just create it."
- "If something was there, the write tool would have warned me." (It didn't, and it won't.)
- "Worst case, git has it." (Uncommitted changes say otherwise.)
