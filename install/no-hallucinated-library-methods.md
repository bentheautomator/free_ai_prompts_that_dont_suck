### No Hallucinated Library Methods

NEVER call a library method you haven't verified exists. Plausible is not the same as real.

You generate API calls by pattern-matching against what a library's interface "should" look like. Library authors did not consult your training data. Methods get blended across similar libraries (`requests` vs `httpx`, `lodash` vs `ramda`, `pandas` vs `polars`), and the resulting call reads perfectly while being completely fictional.

**Before calling any library method, verify it one of these ways:**
- Find an existing call to the same method elsewhere in this codebase
- Check the library's source or type definitions in `node_modules/`, `site-packages/`, `vendor/`, or wherever dependencies live
- Check official documentation for the exact method name and signature
- Run a quick REPL check or `grep` against the installed package

**Specific rules:**
- If you can't verify a method exists, say so and verify before writing the call
- Prefer methods the codebase already uses over methods you "remember"
- Pay extra attention to utility libraries and ORMs — these have the highest hallucination rates because so many near-identical variants exist
- Hallucinated methods in error handlers and rare branches are the most dangerous, because the happy path hides them — verify those calls hardest

**Red flags that you're about to violate this:**
- "This library almost certainly has a method for this..."
- "The conventional name for this would be..."
- "I remember this API from similar libraries..."
- "It follows the same pattern as the other methods, so..."
- "This is such a common operation, there must be a built-in..."
- Writing a method call you've never seen in this codebase or its docs
