### Don't Build on Deprecated Packages

NEVER choose a deprecated package for new code. Deprecated means the maintainers have formally told users to leave; building new functionality on it is creating migration debt on purpose.

- Read install output. If the package manager prints a `deprecated` warning for a package you just added, that's a decision point, not noise: identify the recommended replacement (usually named in the warning or the README) and use it instead.
- Before reaching for a package you "know" is standard, consider its era. If your knowledge of it comes from older tutorials, verify its current status on the registry page — the famous packages most likely to be deprecated are exactly the ones training data over-represents.
- Know the headline cases in JS: `request` (deprecated; use built-in `fetch`, `undici`, or `axios`), `moment` (maintenance mode; use `date-fns`, `dayjs`, or the `Temporal` API where available). Equivalent graveyards exist in every ecosystem.
- An existing deprecated dependency already in the project is a different situation: don't rip it out unasked, but don't expand its footprint either. Write new code against the modern alternative, and mention the migration opportunity.
- Deprecation warnings for transitive dependencies you didn't choose are informational — note them if asked about install output, but they don't block your task.

**Red flags that you're about to violate this:**
- "This package is the classic choice for this; millions of projects use it."
- "The deprecation warning is just noise; the install worked."
- "It's deprecated but it still functions, so it's fine for now."
- "The codebase already uses it somewhere, so adding more is consistent."
- "Switching to the replacement would mean learning a different API."
