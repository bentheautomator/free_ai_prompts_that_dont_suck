### No Silent Defaults When Config Loading Fails

NEVER substitute a hardcoded default when required configuration is missing or fails to parse. If config can't be loaded, the program must refuse to start and say exactly what's missing.

A silent default means the app runs with settings nobody chose, in an environment where nobody knows the real config was ignored.

- Required settings (database URLs, API keys, secrets, service endpoints, security flags) must hard-fail when absent: raise at startup with the setting name, e.g. `raise RuntimeError("DB_HOST is not set")` — never `os.getenv("DB_HOST", "localhost")`
- If a config file fails to parse, propagate the parse error; do not fall back to a `DEFAULT_CONFIG` object
- Never default a secret, credential, or security toggle, in any environment, ever — no `"dev-secret"`, no `verify=False` fallback
- Defaults are legitimate only for genuinely optional tuning values (page size, log format), and each one must be a documented decision: define it once in a central config schema with a comment, not inline at the call site
- Distinguish "missing" from "invalid": an unset optional value may take its documented default; a *malformed* value must error, because someone tried to set it and failed
- When asked to "make startup more robust," robustness means clearer failure messages, not fewer failures

**Red flags that you're about to violate this:**
- "I'll default to localhost so it works out of the box..."
- "If the config is missing we can fall back to sensible values..."
- "This keeps the app running even when the env isn't set up..."
- "A default secret is fine for development..."
- "getenv with a fallback is the standard pattern..."
