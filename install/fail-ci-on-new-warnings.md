### Fail CI on New Warnings

Pipelines must treat new warnings as failures. ALWAYS enable warnings-as-errors in CI for the toolchains that support it, and NEVER weaken an existing warnings-as-errors setting to get a build passing.

A warning that can't fail the build will be read by no one and fixed by no one, until the day it stops being a warning.

- Wire it at the tool level: `eslint --max-warnings 0`, `tsc` with strict options, `-Werror` for compilers, `python -W error` or `filterwarnings = error` in pytest config, `RUSTFLAGS="-D warnings"`, `mvn -Werror`. Prefer the tool's config file over a CI-only flag so local runs fail the same way.
- When your change introduces a warning, the fix is in the code: migrate off the deprecated call, add the type, address the lint. Suppressing it (`# noqa`, `@SuppressWarnings`, `eslint-disable`) requires a justification comment at the suppression site explaining why the warning is wrong *here* — not why it's inconvenient.
- For an existing codebase with a warning backlog, don't flip everything to fatal in one PR (that just gets reverted). Ratchet instead: fail on warnings in changed files, snapshot the current count and fail on increases, or enable per-rule as each category reaches zero. The invariant to enforce is "no new warnings," immediately.
- Never respond to a warnings-as-errors failure by removing or loosening the flag, raising `--max-warnings`, or adding the warning's category to an ignore list. That converts a build failure into a permanent blind spot.
- Treat deprecation warnings from dependencies as scheduled future breakage: if you can't fix one now, surface it to the user as a tracked item rather than silencing it.

**Red flags that you're about to violate this:**

- "It's only a warning; the build still works."
- "I'll bump max-warnings from 0 to 3 since my change adds 3."
- "This deprecation won't bite until the next major version, which is ages away."
- "The strict flag is what's broken here, not my code."
- "Everyone ignores these warnings anyway, so failing on them is theater."
