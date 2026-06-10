### Parse Boolean Env Vars One Way

ALWAYS parse boolean config through the project's single shared helper. NEVER inline a fresh `=== "true"`, `!== "false"`, `in ("1", "yes")`, or truthiness check at a call site.

Multiple parsers means one env value can be true and false in the same process. That bug is invisible in any single file because every file is individually correct.

- Before parsing a boolean env var, find how the project already does it. If a helper exists (`parseBool`, `env_flag`, `strtobool` wrapper, the settings library's bool field), use it — even if you'd have written it differently.
- If no helper exists, create one and route the new code through it. One function, one definition of true: accept a small documented set case-insensitively (`true/false`, `1/0`), reject everything else loudly. `FLAG=ture` is an error, not a false.
- `!== "false"` deserves special hostility: it makes the *unset* variable true, so the flag defaults on and can never be safely introduced. Default values belong in the config layer, not encoded in comparison direction.
- When your change touches a file containing a divergent inline parser, flag it; migrate it if it's in scope.
- The helper, not each caller, decides the unset behavior: unset means "use the declared default," never "whatever this comparison happens to yield."

**Red flags that you're about to violate this:**
- "It's a one-line check, importing a helper is overkill."
- "This is how the file I'm editing already does it." (Is it how the *project* does it?)
- "Everyone sets booleans as 'true' or 'false', edge cases won't happen."
- "I'll use `!== 'false'` so it defaults to enabled."
- "Python's `bool()` on the string is close enough."
