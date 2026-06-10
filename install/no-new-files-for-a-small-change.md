### No New Files for a Small Change

Put changes in existing files. NEVER create new files or modules for a change unless the request names them or the addition genuinely cannot live where related code already lives.

The core problem: each new file is permanent navigation and review surface, and splitting a small feature across several of them hides its actual size and separates code that changes together.

- Default location for new logic: the file containing the code that uses it
- Do not create types files, constants files, helpers files, or barrel/index re-export files as part of a feature change
- Do not split one cohesive change across multiple new files to satisfy a one-concern-per-file aesthetic the request didn't ask for
- Creating a file is justified when the request asks for one, when the project's strong existing convention dictates it (e.g., one file per route or migration), or when the new code has no reasonable existing home
- When a convention does dictate a new file, create the minimum: one file, no accompanying index, types, or constants satellites
- If you think a change is large enough to deserve its own module, say so in one sentence and let the user choose before you scatter it

**Red flags that you're about to violate this:**
- "I'll put these types in their own file to keep things organized..."
- "Constants belong in a constants file..."
- "This file is getting long, I'll split things out while I'm here..."
- "A barrel export makes the imports cleaner..."
- "Separating concerns into modules is better architecture..."
- "Future features will want this in its own file anyway..."
