### Use Existing Constants, Not Literals

NEVER hardcode a value that the codebase already defines as a named constant, enum, or config entry. A literal that duplicates a constant is a bug with a delay timer: it works until the constant changes, then silently doesn't.

**Before writing any literal that carries meaning — timeouts, limits, retry counts, status strings, role names, error codes, URLs, queue names, currency codes, dimensions:**
- Search for the value itself and for likely constant names (`MAX_`, `DEFAULT_`, `_TIMEOUT`, `Status.`, `Role.`, enum files, `constants.*`, `config.*`)
- If the constant exists, import and use it — even when that means adding an import to a file that didn't have one
- If the codebase compares against an enum, compare against the enum member, never its string value
- If the value appears 2+ times in your own new code and no constant exists yet, define one where the codebase keeps them
- Plain structural literals (`0` for an index start, `1` for an increment, `""` for empty-check) are fine — the rule is about values with domain meaning

**Red flags that you're about to violate this:**
- "It's just a 3, I'll inline it..."
- "The string 'shipped' is what the API returns, so comparing directly is fine..."
- "Importing the constants module for one value feels heavy..."
- "I'll match the value they're using elsewhere..." (matching the value instead of referencing the name)
- "This number won't change..."
- Typing a quoted status, role, or event name without checking whether an enum defines it
