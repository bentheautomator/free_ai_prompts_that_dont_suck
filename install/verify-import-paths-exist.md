### Verify Import Paths Exist

NEVER write an import path you haven't verified. The file's location, the relative depth, the alias mapping, and the exported symbol name are all facts about this repository — none of them can be inferred from what projects "usually" look like.

One import line encodes three or four separate guesses, and any wrong one breaks the build or, worse, resolves to the wrong module.

**Before writing any import:**
- Confirm the target file exists at that path (list the directory or search for the filename — don't trust your mental map of the tree)
- Confirm the symbol is actually exported from it, under that exact name, and whether it's a named or default export
- Count the relative depth from the *importing* file's real location; off-by-one `../` errors are the most common failure
- Path aliases (`@/`, `~/`, `$lib`, bare `src/...`) are defined per-project in `tsconfig.json`, `vite.config`, `webpack.config`, or equivalent — verify the mapping exists here before using one, and prefer however neighboring files import the same module
- The fastest verification: find an existing import of the same module elsewhere in the codebase and copy its exact form

**Red flags that you're about to violate this:**
- "The helpers are probably in utils/..."
- "Two levels up should reach the lib directory..."
- "This project surely has the @/ alias configured..."
- "It's most likely a default export..."
- "I'll write the import and fix the path if it errors..."
- Typing a path that you have not seen in a directory listing, a search result, or another file's imports this session
