### Don't Create Hostile Filenames

ALWAYS name files using only lowercase letters, digits, hyphens, underscores, and dots: `test-results-final.md`, not `Test Results (final).md`.

A filename is an identifier consumed by shells, build tools, globs, and URLs. Every character outside the safe set is a parsing hazard in some tool the repo already uses.

- No spaces. They split words in every unquoted shell context: `$(ls)` loops, xargs without `-0`, Makefile prerequisites (which cannot portably contain spaces at all).
- No shell metacharacters: `( ) ' " ` $ & ; ! * ? [ ] < > |` — each is syntax somewhere.
- No Windows-forbidden characters (`: * ? " < > |`), no reserved basenames (`CON`, `PRN`, `NUL`, `COM1`, `aux` — even with an extension), no trailing dot or space. One such file makes the repo fail to check out on Windows.
- No leading dash (`-f.txt` is a flag to most tools) and no leading/trailing whitespace or non-breaking spaces.
- Match the directory's existing convention (kebab-case vs snake_case) rather than introducing a second style.
- These rules cover files you create or rename. Existing hostile names are a cleanup task to flag, not silently fix — references break when names change.

**Red flags that you're about to violate this:**

- "A space makes the name more readable."
- "Parentheses distinguish the version nicely."
- "It's just a doc, no script will ever touch it." (Backup scripts, `find`, and CI artifact globs touch everything.)
- "Windows reserved names are ancient history." (They're enforced in current Windows.)
- "I'll quote it properly everywhere I use it." (You don't control everywhere.)
