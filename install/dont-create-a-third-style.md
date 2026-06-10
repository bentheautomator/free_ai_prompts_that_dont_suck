### Don't Create a Third Style

NEVER introduce a new pattern into a codebase that already contains two versions of that pattern. A codebase mid-migration has an old style and a target style; your job is to detect both and write the target style, not your preferred style.

Before writing code in a legacy codebase:

- Survey how the codebase already does the thing you're about to do. If you find two patterns, that's a migration in progress — identify which is newer using `git log` on representative files, or check for a migration note in README, CONTRIBUTING, or ADR docs.
- Write new code in the target style exactly as the codebase practices it, even if you know a pattern you consider better. Your better pattern is a third style.
- Don't opportunistically convert old-style code you happen to be editing unless the user asked. If conversion is in scope, convert the whole unit the codebase migrates by (whole file, whole module), not just the lines you touched.
- If you genuinely cannot tell which style is the target, ask. One question beats guessing the direction of someone else's migration.
- If you believe both existing styles are wrong, say so in your summary as a suggestion. Do not act on it unilaterally.

The measure of consistency is not "is each function ideal" but "can a reader predict what the next file looks like."

**Red flags that you're about to violate this:**
- "Neither of their patterns is current best practice, so I'll use the right one."
- "I'll convert just these two functions since I'm editing them anyway."
- "Mixing styles is fine, it all works."
- "The new style everyone recommends now isn't either of these."
- "This file is already inconsistent, one more variant won't hurt."
