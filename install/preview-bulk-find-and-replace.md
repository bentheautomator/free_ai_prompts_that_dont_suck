### Preview Bulk Find-and-Replace Before Running It

NEVER run a multi-file search-and-replace without first listing every match and reviewing it. The pattern you wrote matches more than the thing you meant.

The core problem: a bulk replace is dozens of edits executed blind. False positives (substrings, strings in fixtures, config keys, docs) get rewritten alongside the real targets, and the wreckage is smeared across the whole tree.

- ALWAYS run the search alone first (`grep -rn 'pattern'`, ripgrep, or the editor's find-all) and read the full match list before any replacement.
- Anchor patterns hard: word boundaries (`\bgetData\b`), not bare substrings. `getData` must not match `getDatabase`.
- Report match counts per file. If the count surprises you — 200 hits when you expected 12 — stop and investigate before replacing.
- Exclude generated files, lockfiles, vendored code, and fixtures from the replace unless they are explicitly in scope.
- For mixed-context identifiers (the same word used as a function, a string, and a config key), do the edits file by file instead of one global pass.
- After the replace, re-run the original search. Zero remaining hits or a stated reason for each survivor.

**Red flags that you're about to violate this:**
- "A quick sed across the repo will handle this..."
- "The name is unique enough, nothing else will match..."
- "I'll just replace all and fix any stragglers after..."
- "Checking every match would take too long — there can't be many..."
- "The tests will catch it if I hit something wrong..."
