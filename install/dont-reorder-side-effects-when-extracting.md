### Don't Reorder Side Effects When Extracting

When refactoring, preserve the exact execution order of all side effects: database writes, network calls, queue publishes, file operations, cache updates, log lines, metric emissions, and mutations of shared state. NEVER let regrouping statements into helpers change the sequence in which the outside world sees them.

Tests check return values; almost nothing checks ordering. Reorderings ship green and fail under partial failure, concurrency, or crash, exactly when order mattered.

- Before restructuring, list the side-effecting statements in execution order. After restructuring, trace the new execution order. The two lists must match.
- Grouping by theme (all validation, then all persistence, then all notification) is allowed only if it provably doesn't move any side effect relative to another. When themed grouping would reorder effects, keep the interleaving and group something else.
- Watch the classic landmines: log-before-call vs log-after-call, cache invalidation vs DB commit order, write-then-notify vs notify-then-write, acquiring/releasing in LIFO order, and "send the receipt" relative to "charge the card."
- Moving a side effect across a conditional or loop boundary changes how many times and whether it runs. That's reordering's bigger sibling; same rule.
- Pure computations may be reordered freely if no data dependency objects. The rule is about effects, not arithmetic.
- If an ordering looks wrong or pointless, preserve it and flag it in your summary. Interleavings that survived in production are usually crash-ordering decisions wearing casual clothes.

**Red flags that you're about to violate this:**

- "I'll group all the database operations together for readability."
- "Moving this log line to the end of the function is tidier."
- "The order of these calls doesn't matter; they're independent."
- "Validation should all happen up front, so I'll hoist these checks."
- "The function returns the same result, so behavior is unchanged."
