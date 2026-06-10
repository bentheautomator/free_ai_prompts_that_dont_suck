### No Environment-Dependent Tests

A test must pass on any machine: any timezone, any locale, any OS, any shell. NEVER let a test's outcome depend on environment properties it doesn't explicitly control.

The core problem: environment assumptions enter silently — through locale-default formatting, local-time date parsing, OS path behavior, ambient env vars — and produce tests that pass for the author and fail for everyone else.

Rules:
- Timezone: never assert local-time renderings of a timestamp without pinning the zone. Construct dates explicitly in UTC (`Date.UTC(...)`, ISO strings with offsets, `datetime(..., tzinfo=timezone.utc)`); if the code under test formats in local time, set the zone for the test (`TZ=UTC` for the run, `timezone_machine`/library-level zone injection) and say which zone you pinned
- Locale: `toLocaleString`, `strftime` month names, decimal separators, and collation-based sort orders all vary by locale. Either pass the locale explicitly to the formatting call/assertion, or pin it for the test — never lean on the machine default
- Environment variables: a test that needs one sets it itself (via restoring mechanisms); a test that must not be affected by one clears it. Never depend on whatever the invoking shell exports
- Filesystem and OS: don't rely on case-insensitive filenames, path separator quirks, `/tmp` semantics, or tool availability (`which gsed`) that differ across platforms — build paths with the stdlib's path APIs and gate genuinely platform-specific tests with explicit, visible skips
- Network and ambient services: a unit test that touches a real host or assumes a port is free inherits every property of the machine around it; fake the boundary instead
- Review your own assertions for locale/zone fingerprints: slashes vs dots in dates, AM/PM, comma decimals, month names — each one is an assumption about the machine, written as an expectation about the code

**Red flags that you're about to violate this:**
- "The formatted output is 06/10/2026 here, so that's the expected value..."
- "CI also runs Linux, the path handling will be the same everywhere..."
- "That env var is always set in practice..."
- "toLocaleString output is stable enough to assert on..."
- "It passes on my run, the test is correct..."
