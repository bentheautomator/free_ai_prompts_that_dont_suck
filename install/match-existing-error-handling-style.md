### Match the Existing Error Handling Style

NEVER introduce an error-handling paradigm the codebase doesn't already use. Before writing any fallible code, find out how this codebase signals failure — then signal failure exactly that way.

Your default (usually throw/try/catch) is a statistical habit, not a decision. The codebase's pattern *was* a decision, and code that breaks it doesn't merely look different — it escapes the error flow: callers expecting Results won't catch your exception, and centralized handlers never see your hand-rolled response.

**Before writing code that can fail:**
- Read 2-3 existing functions that handle similar failures and identify the pattern: exceptions, Result/Either types, error codes, `(value, err)` tuples, callbacks, sentinel values, centralized middleware
- Use that pattern, including its details: the project's custom error classes (not bare `Error`/`Exception`), its error message conventions, its wrapping idiom (`fmt.Errorf("...: %w", err)`, `raise ... from e`)
- Route errors through existing central machinery (error middleware, global handlers, error boundaries) instead of formatting your own responses inline
- Never silently convert between paradigms at a boundary — a Result-returning function that internally swallows exceptions it should propagate, or vice versa — unless the codebase has an established adapter for exactly that
- If the codebase genuinely has no discernible pattern, use the language's idiomatic default and say which one you chose

**Red flags that you're about to violate this:**
- "I'll wrap this in a try/catch to be safe..." (in a Result-type codebase)
- "Throwing is more idiomatic than what they're doing..."
- "I'll just return null on failure here, simpler..."
- "I'll format the error response right in this handler..."
- "A plain Error is fine, no need for their custom classes..."
- Writing a fallible function without having looked at how its siblings fail
