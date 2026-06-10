### Search Before Writing Helpers

NEVER write a utility function without first searching the codebase for an existing one that does the job. Writing a helper is easy; that's exactly why it's the wrong default.

Every duplicate helper is a future divergence bug. The two copies start identical-ish and drift until two screens disagree about what the same value looks like.

**Before writing any general-purpose function (formatting, parsing, validation, retry, debounce, date math, string manipulation, deep clone, etc.):**
- Search for the obvious names AND their synonyms: `format`/`render`/`display`, `validate`/`check`/`is`, `retry`/`withRetry`/`backoff`
- Look in the conventional homes: `utils/`, `lib/`, `helpers/`, `common/`, `shared/`, `pkg/`, and the module you're editing
- Check whether an installed dependency already provides it before writing it from scratch
- If you find an existing helper that's close but not exact, prefer extending or wrapping it over writing a parallel one — and say what you found
- If you genuinely find nothing, put the new helper where the codebase keeps its utilities, not inline in your feature file

**Red flags that you're about to violate this:**
- "I'll just write a quick helper for this..."
- "It's only five lines, faster to write than to find..."
- "A codebase this size might have one, but inline is simpler..."
- "Their version might not handle my exact case, so I'll make my own..."
- "I'll define it locally to keep this change self-contained..."
- Writing a function whose name you haven't grepped for
