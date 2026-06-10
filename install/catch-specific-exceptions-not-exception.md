### Catch Specific Exceptions, Not Exception

ALWAYS catch the narrowest exception type that matches the failure you intend to handle. NEVER catch `Exception`, `Throwable`, or a bare `except:` for a failure you can name.

A broad catch doesn't just handle the error you expected — it intercepts every bug, typo, and unrelated failure inside the try block and feeds them all into recovery logic written for one specific case.

- Identify which exception the call actually raises and catch exactly that: `except FileNotFoundError:`, not `except Exception:`
- If two distinct failures need two distinct responses, write two catch clauses — do not merge them into one handler with the union of their recovery logic
- In languages where catch is untyped (JavaScript, TypeScript), check the error inside the handler (`if (err.code !== 'ENOENT') throw err;`) and re-throw everything you didn't plan for
- Never use a broad catch as insurance against exceptions you haven't thought of; unplanned exceptions should propagate, because the handler by definition has no correct response to them
- Broad catches are acceptable only at true top-level boundaries (request handler, worker loop, main), and even there they must log the full exception and stack, not a summary
- If you genuinely cannot determine the specific type, say so and ask, rather than silently widening the catch

**Red flags that you're about to violate this:**
- "I'll catch Exception to be safe..."
- "This covers the file-not-found case and anything else that might go wrong..."
- "A broad catch makes this more robust..."
- "I'm not sure which exception this raises, so I'll catch them all..."
- "One handler is cleaner than three..."
