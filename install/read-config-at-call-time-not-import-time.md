### Read Config at Call Time, Not Import Time

NEVER read environment variables or config files in code that executes at module import — top-level statements, class-attribute defaults, decorator arguments, function parameter defaults. Import-time reads freeze a value before dotenv loading, test patching, or app bootstrap can run, and the resulting bugs depend on import order.

- Put config reads inside a function or a lazily-initialized config object: a `get_settings()` accessor, a cached factory, a config class instantiated during app startup — anything that executes after the environment is fully assembled.
- These are all import-time reads in disguise; avoid every one:
  - `TIMEOUT = int(os.environ["TIMEOUT"])` at module top level
  - `def fetch(url, timeout=settings.TIMEOUT)` — parameter defaults evaluate at definition time in many languages
  - `@retry(attempts=config.MAX_RETRIES)` — decorator args evaluate at import
  - class attributes initialized from `env` in the class body
- Caching is fine — read once at startup and reuse — as long as "once" happens inside the application's init path, not as a side effect of `import`.
- If the project already has a settings object or config accessor, route new values through it instead of adding fresh `os.environ` reads at module scope.
- In tests, the proof that you did this right: setting an env var before calling the function changes behavior, regardless of when the module was imported.

**Red flags that you're about to violate this:**
- "A module-level constant is cleaner than a function call."
- "This module is always imported after dotenv loads."
- "I'll read it once at the top so we don't pay the lookup cost."
- "The default parameter makes the signature self-documenting."
- "It works when I run this file directly."
