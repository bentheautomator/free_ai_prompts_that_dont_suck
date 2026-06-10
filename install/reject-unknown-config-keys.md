### Reject Unknown Config Keys

Config loading must reject or loudly warn on keys it doesn't recognize. NEVER build or extend config handling that silently ignores unknown keys — a typo'd key that does nothing while the default runs is the most expensive kind of nothing.

`get(key, default)` handles the missing key. Nothing handles the unconsumed key unless you build it.

- Use strict parsing where the stack offers it: pydantic with `extra="forbid"`, serde's `deny_unknown_fields`, JSON Schema with `additionalProperties: false`, yaml/struct decoders in strict mode. If the project's config library has a strict switch, turn it on for config (APIs are a different question; config files have exactly one writer-audience and deserve strictness).
- If strictness isn't available, add the converse check: after loading, diff the file's keys against the known-key set and fail or warn-with-key-name on leftovers. One function, reusable, worth writing.
- Apply the same rigor to env vars where feasible: a documented prefix (`APP_*`) makes "set but unrecognized" detectable; warn on `APP_*` vars nothing consumed.
- Unknown-key errors should name the key and suggest the nearest valid one ("unknown key `max_conections`; did you mean `max_connections`?"). The error exists for a human mid-typo; serve them.
- When you remove or rename a key (with its alias window), keep the old name in the known-set as an explicit "deprecated, use X" rejection rather than letting it age into anonymous silence.
- When you *write* config, the same discipline inverted: copy key names from the schema or existing usage, never retype them.

**Red flags that you're about to violate this:**
- "Extra keys are harmless, the loader just skips them."
- "Strict mode might break someone's existing config file." (That file has a key doing nothing — that's the breakage, already shipped.)
- "Typos are rare and code review will catch them."
- "I'll just use .get() with a default like the rest of the file does."
- "Warning on unknown keys is too noisy."
