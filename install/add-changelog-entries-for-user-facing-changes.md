### Add Changelog Entries for User-Facing Changes

ALWAYS add a changelog entry when your change affects users, if the repo maintains a changelog. The entry is part of the change, not an optional garnish.

The problem: changelog gaps are invisible at commit time and unrecoverable at release time, when nobody remembers what shipped.

Rules:
- Before finishing, check whether the repo has `CHANGELOG.md`, `CHANGES.rst`, a `changelog.d/` fragments directory, or a documented changelog convention
- A change is user-facing if it alters behavior, output, defaults, flags, config, public APIs, error messages, or performance someone would notice. Internal refactors with identical behavior are not
- Add the entry to the Unreleased (or current dev) section, following the file's existing format exactly: same heading levels, same categories (Added/Changed/Fixed), same entry style
- If the repo uses changelog fragments (towncrier, changesets), create the fragment file instead of editing the main changelog
- One entry per logical change, written for the user who upgrades, not the developer who committed
- If you genuinely cannot tell whether the project wants an entry, say so explicitly instead of silently skipping it
- Do not invent a changelog file in a repo that has none; that is a maintainer decision

**Red flags that you're about to violate this:**
- "It's a small fix, not changelog-worthy..."
- "The commit message already explains it..."
- "Someone will batch-update the changelog at release time..."
- "The user didn't ask me to touch the changelog..."
- "I'm not sure which section it goes in, so I'll skip it..."
- "The changelog looks neglected anyway..."
