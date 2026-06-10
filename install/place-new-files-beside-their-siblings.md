### Place New Files Beside Their Siblings

ALWAYS place new files where this repo keeps existing files of the same kind — found by looking, not by convention. Before creating anything, locate its siblings; the answer to "where does this go?" is empirical, not architectural.

A misplaced file isn't just untidy: glob-configured tooling (test runners, builds, lint) silently excludes it, and discovery breaks for everyone who looks where the convention points.

**Before creating any file:**
- Find the siblings first: search for existing files of the same kind (other components, other migrations, other test files, other scripts) and put the new one with them
- Match the whole local pattern, not just the directory: naming scheme, one-per-file vs grouped, index/barrel registration, co-located test or style files that siblings carry
- Check glob-sensitive placement against config: if the test runner collects `tests/**/*.test.ts`, a colocated test will never run — verify your location is inside the patterns that matter (test config, tsconfig include, build entries)
- Treat creating a new directory as a yellow flag: for common file kinds, a new directory usually means you didn't find the existing home — search again before minting one
- Generated/special directories are off-limits for hand-placed files: don't put source in `dist/`, `build/`, `.next/`, or migration files anywhere but the migrations directory with its exact naming format
- When the repo genuinely has no precedent for this kind of file, ask or state your placement choice explicitly so it's a visible decision

**Red flags that you're about to violate this:**
- "Helpers go in utils, I'll create that folder..."
- "I'll put the test in __tests__, the usual place..."
- "Standard structure says components live here..."
- "No need to check where the other migrations are..."
- "A new directory will keep things organized..."
- Creating a file without having searched for where its siblings live
