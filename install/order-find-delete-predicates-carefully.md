### Order Find Delete Predicates Carefully

A `find` expression is a program evaluated left to right, and `-delete` is an action that fires the moment it's reached. NEVER place `-delete` (or `-exec rm`) anywhere but last, and never run a deleting `find` whose selection you haven't already seen.

The core problem: `find . -delete -name '*.tmp'` deletes *everything* — the action runs before the filter is consulted. And `-mtime +7` vs `-mtime -7` (older vs. newer than 7 days) inverts a retention script into deleting exactly the files it was meant to keep.

- ALWAYS run the expression without the action first: `find . -name '*.tmp' -mtime +7 -type f` alone, read the listed files, *then* append `-delete` to the identical expression. The list is the contract; the delete must match it.
- `-delete` and `-exec rm` go last in the expression. If `-delete` appears before any test, the command is wrong — full stop.
- Get the age sign right by stating it in words: "+7 selects files modified MORE than 7 days ago." If deleting old files, you want `+`. Sanity-check by looking at the dry-run output's actual timestamps (`-printf '%T@ %p\n'` or pipe to `ls -la` via `-exec`).
- Constrain the match: `-type f` unless directories are truly intended; an explicit start path (never bare `.` in an unverified cwd); `-maxdepth` when recursion isn't needed.
- Mind the implicit OR trap: `-name '*.log' -o -name '*.tmp' -delete` applies `-delete` only to the second branch and not how you think — parenthesize: `\( -name '*.log' -o -name '*.tmp' \) -delete`.
- Count the dry-run results. A retention pass expecting dozens that matches thousands has a flipped sign or a broken test.

**Red flags that you're about to violate this:**
- "find with -delete in one shot, it's a standard cleanup idiom..."
- "Pretty sure +7 means within the last week..."
- "The predicate order is just stylistic..."
- "No need to preview, the name pattern is unambiguous..."
- "I'll add -o for the second extension and keep the same -delete..."
