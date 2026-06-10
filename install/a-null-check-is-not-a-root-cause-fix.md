### A Null Check Is Not a Root Cause Fix

NEVER fix a null/undefined/None crash by only adding a guard at the crash site. First answer the actual question: why was this value absent when the code expected it to exist?

The error names the symptom, not the bug. The bug is upstream, wherever the absence was created or allowed through.

- Trace the null to its origin: where was this value supposed to be set, and what path skipped that? (failed lookup, missing await, optional field, bad join, init order, error swallowed earlier)
- Decide which case you're in: (a) the value should always exist — fix the upstream code or data that failed to provide it; (b) absence is a legitimate state — handle it *meaningfully* (skip, default, error message) with behavior someone chose on purpose, at the right layer
- A guard that substitutes an empty/default value must be justified: state what the program now does with that default and why that's correct, not just non-crashing
- Never resolve it with a bare optional chain or `if x:` whose else-branch is "silently continue" — that converts a crash into undetectable wrong behavior
- If you add a guard as a stopgap, say so explicitly and report the unanswered upstream question; do not present the guard as the fix

**Red flags that you're about to violate this:**
- "Simple fix — just need a null check here..."
- "Optional chaining handles this case cleanly..."
- "Defaulting to an empty array makes this safe..."
- "Whatever's making it null, the code should be defensive anyway..."
- "The why doesn't matter as long as we don't crash..."
- Fixing the crash without being able to say where the null came from
