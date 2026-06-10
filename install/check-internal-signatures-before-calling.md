### Check Internal Signatures Before Calling

NEVER call a project function whose definition you haven't read in this session. The name tells you what it probably does; only the definition tells you what it takes, in what order, and what comes back.

Internal functions are guessed at more confidently than library ones — no docs to check means nothing contradicts the guess. The silent failure is two same-typed parameters in the wrong order: no error, wrong result.

**Before writing a call to any function defined in this codebase:**
- Read the actual definition: parameter names, order, types, defaults, keyword-only/positional rules, and what's optional
- Read the return shape: object vs tuple, raw value vs wrapper, what's `None`/`null` when, whether it throws or returns errors
- Or read an existing call site and mirror it exactly — a working call is a verified signature
- Same-typed adjacent parameters (`(from, to)`, `(width, height)`, `(percent, price)`) deserve a second look: order mistakes here produce wrong answers, not errors
- Async matters too: confirm whether it returns a promise/coroutine you must await — calling an async function like a sync one fails quietly in some languages
- If you change your understanding mid-task ("oh, it takes a payload object"), re-check the *other* calls you already wrote against the corrected signature

**Red flags that you're about to violate this:**
- "Based on the name, this function takes..."
- "It probably returns the user object directly..."
- "The natural argument order would be..."
- "I called it this way earlier in the file..." (was that call verified, or also guessed?)
- "It's our own function, the shape will be obvious..."
- Writing a call to an internal function whose definition you have not had on screen
