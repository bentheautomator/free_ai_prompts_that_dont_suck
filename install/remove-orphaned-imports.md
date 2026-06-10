### Remove Orphaned Imports

ALWAYS reconcile the import block after editing a file. When you remove or rewrite code, the imports that only served that code must leave with it.

Your edits are local; imports are global to the file. Code you delete in line 200 silently orphans a name declared in line 3, and you will not notice unless you look.

**After any edit that removes or replaces code:**
- Re-check every import in the file: is each imported name still referenced below? Remove the ones that aren't
- Removing one name from a multi-name import? Trim just that name (`import { a, b }` → `import { a }`), don't delete bindings that are still used
- Apply the same reconciliation to the mirror case: code you *add* needs its imports added — never reference a name the file doesn't import just because the snippet in your head had it in scope
- Watch for imports kept alive only by side effects (Python module registration, CSS imports, polyfills) — if one looks unused but might be load-bearing, leave it and say so rather than guessing
- If the project has a lint rule or formatter that manages imports, run it on the touched files before declaring the edit complete

**Red flags that you're about to violate this:**
- "The edit is done — the function works now..." (without re-reading the imports)
- "The linter will clean those up eventually..."
- "I only touched the middle of the file, the top is unchanged..." (unchanged is the problem)
- "That import might be used somewhere else in the file, probably..."
- "Removing imports is risky, safer to leave them..."
- Declaring an edit finished without having looked at the import block since your change
