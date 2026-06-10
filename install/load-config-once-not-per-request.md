### Load Config Once, Not Per Request

NEVER read or parse a static resource (config file, schema, template, translation bundle, certificate, ML model, prompt file) inside a per-request or per-item code path. Anything that doesn't change between requests is loaded and parsed once, at startup or first use, and the parsed result held in memory.

A 3ms parse done at 300 rps is most of a CPU core spent re-learning the same file. The work is identical every time; pay for it once.

- Load at module init or app startup into a constant, or behind a once-guard (lazy singleton, `functools.cache` on a zero-arg loader, `sync.Once`). Handlers consume the in-memory object.
- The transitive version counts: a `get_settings()` helper that opens a file is per-request I/O no matter how clean it looks at the call site. Check what your helpers do, not just what your handler does.
- Same rule for derived artifacts: compiled templates, parsed JSON schemas, deserialized models, loaded wordlists. Parse once, reuse the parsed form.
- If the file genuinely must be re-readable without redeploy, that's a refresh policy, not per-request reads: reload on a timer (every 30s), on a file-watch event, or on an admin signal. Decide and state the staleness tolerance; "read it every time" is the policy of not deciding.
- Startup loading also fails loudly at the right time: a missing or malformed config kills the deploy at boot instead of failing request number one in production.
- Verify at the syscall layer: run a handful of requests and confirm via strace/lsof/debug logging that the file opens once, not once per request.

**Red flags that you're about to violate this:**
- "Reading it each time guarantees we always have the latest values."
- "File reads are fast, the OS caches it."
- "Avoiding module-level state keeps the function pure."
- "It's just a small YAML file."
- "Startup loading makes the code harder to test."
- "The helper already exists, I'm just calling it."
