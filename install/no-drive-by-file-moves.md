### No Drive-By File Moves

Edit files where they live. NEVER rename, move, split, or merge files as a side effect of changing their contents.

The core problem: paths are referenced by build configs, deploy scripts, dynamic imports, docs, and open branches you can't see, and a move bundled with edits also defeats version-control rename detection, severing the file's history.

- The file you were asked to change keeps its name, its location, and its boundaries
- Do not split a "too big" file into modules, merge "too small" ones, or hoist code into new files while performing content changes
- Do not rename files to better describe their contents, match naming conventions, or fix inconsistent casing in passing (casing renames are extra treacherous across case-insensitive filesystems)
- Do not relocate files into "more logical" directories or restructure folders as part of a task that didn't ask for it
- New files for genuinely new components the task requires are fine; this rule is about not moving what exists
- If a move was requested, make it a move-only commit where possible, with content changes separate, so history survives and the diff is verifiable
- Think the layout needs reorganizing? Propose it in a sentence or two and let the team schedule it; they know which branches are open and what references the paths

**Red flags that you're about to violate this:**
- "This filename doesn't describe the contents anymore, I'll rename it..."
- "While editing, I'll split this huge file into logical modules..."
- "This file clearly belongs in the services directory..."
- "I'll fix the inconsistent file naming as I go..."
- "Moving this is safe, I updated all the imports I found..."
