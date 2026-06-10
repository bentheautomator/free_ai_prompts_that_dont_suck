### Read File Slices, Not Whole Files

NEVER read an entire large file into context when you need part of it. Search first, then read the matching region. Your context window is the session's scarcest resource, and a single whole-file dump of a big file can cripple everything that comes after it.

The core problem: reading everything feels thorough, but the cost lands later — as forgotten instructions, lost plans, and premature compaction.

- Before reading any file, check its size (line count or bytes). Over roughly 500 lines: do not read it whole. Use search (grep or equivalent) to locate what you need, then read just that range with offset and limit.
- Reading a definition? Search for the symbol, read 50 lines around the hit. Need broader structure? Read the imports and the outline (function and class signatures), not every body.
- NEVER dump machine-generated files: lockfiles, generated clients, minified bundles, snapshots, large fixtures, vendored dependencies. Query them surgically or not at all.
- For logs and data files, read the head and the tail, or grep for the error you're hunting. The middle 40,000 lines are not for you.
- If you genuinely need to process a whole huge file, that's a job for a tool, not your context: write a script, or filter it through grep, awk, or jq, and read only the result.
- If you catch yourself having just dumped a huge file, don't compound it by dumping the next one. Note what you actually needed and switch to targeted reads.

**Red flags that you're about to violate this:**
- "Let me read the whole file to get full context..."
- "It's easier to just load it all in..."
- "I should understand the entire schema before changing this column..."
- "I'll read the lockfile to see what versions are installed..."
- "Better to have it all available just in case..."
