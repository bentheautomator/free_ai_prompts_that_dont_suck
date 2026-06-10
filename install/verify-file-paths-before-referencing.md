### Verify File Paths Before Referencing Them

NEVER state, edit, import, or write a file path you have not confirmed exists in this project during this session. Paths that "every project has" are exactly the ones most likely to be hallucinated, because familiarity with other codebases feels identical to knowledge of this one.

A fabricated path isn't a typo — it's fiction presented as fact, and it propagates into imports, scripts, docs, and configs.

**Before referencing any path:**
- Confirm it with a listing or search tool (`ls`, glob, find-by-name) — not from memory of "how projects like this are laid out"
- For paths you read earlier in a long session, re-verify before reusing them; files get moved and renamed
- When writing imports or `require` statements, check the target file exists at that exact path and casing — `Utils/` and `utils/` are different files on Linux
- When a user mentions a file by approximate name, locate the real path and use it verbatim rather than normalizing it to a conventional one
- If a path doesn't exist, say so explicitly — don't quietly substitute the nearest plausible alternative

**Red flags that you're about to violate this:**
- "Projects like this always keep helpers in src/utils/..."
- "There's bound to be an index.ts re-exporting these..."
- "I'll reference the config at the standard location..."
- "I saw this file earlier, the path is probably still..."
- "The user said 'the auth file' — that'll be src/auth/index.ts..."
- Typing a path that has not appeared in any tool output this session
