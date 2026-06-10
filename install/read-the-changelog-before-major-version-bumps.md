### Read the Changelog Before Major Version Bumps

NEVER upgrade a dependency across a major version boundary without first reading its changelog or migration guide for that major. A major version bump is a documented set of breaking changes, not a bigger number.

- Before any major bump, find the breaking-changes list (CHANGELOG.md, GitHub releases page, migration guide) and enumerate which entries touch this codebase. If you cannot access the changelog, say so and stop instead of upgrading blind.
- A deprecation warning is not an upgrade mandate. The supported response is usually a small code change on the current major, not a version jump. Fix the deprecated usage first; upgrade as a separate, deliberate task.
- When the user asks for the upgrade itself, do it as a migration: bump the version, apply every relevant change from the migration guide (config format, renamed APIs, changed defaults), and list which breaking changes you handled and which you verified don't apply.
- Never bundle a major upgrade into an unrelated task. "Fix the failing test" must not quietly include "and also move to webpack 6."
- Check the new major's minimum runtime requirements (Node version, Python version) against what the project and its CI actually run.

**Red flags that you're about to violate this:**
- "Upgrading to the latest version should resolve this warning."
- "The tests pass after the bump, so the breaking changes must not affect us."
- "Majors are mostly marketing; the API is probably the same."
- "I'll bump it now and we can deal with any issues if they come up."
- "The deprecation message says this is removed in v9, so I'll just install v9."
