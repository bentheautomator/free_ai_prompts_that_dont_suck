### Decide What Empty Env Vars Mean

Every env var read must deliberately handle three states — unset, empty, set — and the project must handle them ONE way. NEVER let the choice between `||` and `??`, or between `in os.environ` and `os.environ.get(...)`, silently make that decision per call site.

`FOO=` is set and empty. Compose files, CI interpolation, and templating produce that state routinely; code that only imagines two states hands `""` to something that needed a URL.

- Default policy, unless a key documents otherwise: empty means unset. Strip whitespace; if nothing remains, behave exactly as if the variable were absent (apply the default, or fail if required). This matches how empties are produced — by accident.
- Required-var validation must reject empty, not just absent. `if not os.environ.get("DATABASE_URL"):` is correct; `if "DATABASE_URL" not in os.environ:` waves `DATABASE_URL=` straight through to the connection code.
- If a key gives empty a real meaning ("empty CORS_ORIGINS = allow none"), that's an exception: document it at the key's declaration, and prefer an explicit sentinel (`CORS_ORIGINS=none`) over load-bearing emptiness.
- Implement the policy once, in the config layer's read helper — not re-decided by each call site's choice of `||` vs `??`. In JS specifically, treat a bare `??` on `process.env` as a flag: it asserts that empty string is a meaningful value. Is it?
- Extend the same three-state thinking to file-based config: a key present with `null`/`""` versus a key absent. Loaders that collapse those differently than your env handling create the same bug one format over.

**Red flags that you're about to violate this:**
- "I checked that the variable is set, so it has a value."
- "Nobody sets a variable to empty on purpose." (Correct — that's why it happens by accident.)
- "`??` and `||` do basically the same thing here."
- "The empty string will just fail validation downstream anyway."
- "Compose always passes our variables through, the value will be there."
