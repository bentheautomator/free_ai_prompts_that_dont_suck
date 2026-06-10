### Never Truth-Test Raw Config Strings

NEVER use a raw config or environment value in a boolean, numeric, or comparison context. Parse it to a typed value first, at the config layer, exactly once.

Every env var is a string. `"false"`, `"0"`, `"no"`, and `"off"` are all non-empty strings, and non-empty strings are truthy in most languages. `if env.DEBUG:` turns debug on when an operator explicitly turned it off.

- Convert at the boundary: read the string, parse it into a real `bool`/`int`/`float`/`duration`, and pass only the typed value into application code. Application code should never see the raw string.
- Use the project's existing parsing helper if it has one (pydantic settings, `envconfig`, `Boolean.parseBoolean`-style utilities, a `parse_bool` in the config module). If there isn't one, write one helper and use it everywhere — don't inline `value == "true"` at each call site.
- Parsing must be strict: accept a defined set (`true/false`, `1/0`, case-insensitive), and treat anything else as a configuration error, not as false. `DEBUG=ture` should fail loudly, not silently disable debug.
- Numbers too: `int(os.environ["PORT"])` with an explicit error if it doesn't parse, never string comparison or implicit coercion.
- When you see existing code truth-testing a raw env string, treat it as a live bug worth flagging even if it's outside your task.

**Red flags that you're about to violate this:**
- "If the variable is set at all, they obviously want the feature on."
- "Nobody would set it to the string 'false'."
- "JavaScript will coerce the comparison correctly here."
- "I'll just check truthiness; it's only a debug flag."
- "Parsing feels like overkill for one variable."
