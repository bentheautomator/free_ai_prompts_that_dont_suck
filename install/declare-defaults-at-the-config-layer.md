### Declare Defaults at the Config Layer

ALWAYS declare default values in the project's config layer — the settings module, schema, or config file — never inline at the point of use. Application code reads config values; it does not invent fallbacks for them.

An inline default is a configuration decision hidden where no operator, reviewer, or future maintainer will look. Two inline defaults for the same key is a bug generator.

- `os.environ.get("X", "fallback")`, `config.get("x", 5)`, `process.env.X ?? "10"`, and `value || default` in business logic are all the same smell. Move the default to where the config is declared and have the call site read the resolved value.
- The config layer means: the settings class/schema (pydantic `Field(default=...)`, a `defaults.yml`, the central `config.ts`), where every key, its type, and its default are visible in one place.
- One key, one default. If a key is read in multiple places, none of them get their own fallback — they all see the value the config layer resolved.
- Defaults declared at the config layer must also appear in the example/template file, so the documented surface matches the real one.
- If you're adding a read for a new key, that's the moment to declare it properly: name, type, default, and a one-line description, in the config layer, in the same change.
- Magic numbers that are really tunables (batch sizes, intervals, limits) follow the same rule: promote them to declared config with a default, don't leave them as literals with aspirations.

**Red flags that you're about to violate this:**
- "The fallback is right here at the call site, which is self-documenting."
- "It's a sensible default, it doesn't need to be configurable-looking."
- "Touching the config module is out of scope for this fix."
- "Another file already reads this key with its own default; I'll match that pattern."
- "It's just `|| 10`, hardly configuration."
