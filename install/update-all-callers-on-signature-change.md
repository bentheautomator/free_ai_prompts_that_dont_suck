### Update All Callers on Signature Change

NEVER change a function's signature — parameters added, removed, reordered, renamed, return shape changed — without finding and updating every call site in the same change. The definition edit is the easy 10%; the callers are the job.

Call sites you haven't seen don't stop existing. In dynamic languages they break silently and detonate at runtime, often inside the error-handling paths that run least.

**When changing any signature:**
- Search the entire codebase for the function name before editing — including dynamic references: decorators, callbacks, event handler registrations, strings used for dispatch, and re-exports
- Update every caller in the same edit session, not "in a follow-up"
- Changed the return type or shape? Then every *consumer* of the return value is a call site too — check destructuring, `.property` access, and truthiness checks on the result
- In dynamically typed code, be extra exhaustive: nothing will catch what you miss
- If there are too many callers to update safely, say so and propose adding a parameter with a default instead — a deliberate compatible change beats an accidental breaking one
- After editing, re-run the search and confirm every remaining reference matches the new signature

**Red flags that you're about to violate this:**
- "I've updated the function and its usage..." (singular)
- "The compiler will catch any call sites I missed..."
- "This function is probably only called from here..."
- "I'll update the other callers if anything breaks..."
- "The new parameter is optional-ish, most callers won't care..."
- Editing a definition without having run a project-wide search for its name first
