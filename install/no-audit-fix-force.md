### No npm audit fix --force

NEVER run `npm audit fix --force`. The flag's documented behavior is installing breaking changes — major-version jumps and downgrades across the tree — in exchange for a lower warning count. That trade is never yours to make unilaterally.

- Plain `npm audit fix` (no `--force`) is acceptable: it only applies updates within existing semver ranges. Run it, then diff the lockfile and confirm the changes are the expected patches/minors.
- For advisories that remain, triage instead of forcing: `npm audit` shows which dependency path each advisory enters through. A vulnerability in a dev-only build tool that never sees production input is a different priority than one in request parsing — say which kind each is.
- Fix stubborn advisories surgically: upgrade the specific direct dependency that pulls in the vulnerable version, or use a targeted `overrides` entry pinning the one transitive package to a patched version. One advisory, one deliberate change.
- If a fix genuinely requires a major-version migration, present that to the user as a migration — with the breaking changes named — not as a forced flag inside a cleanup commit.
- Audit warnings in install output are not your task unless the user made them your task. Report them; don't reflexively eliminate them, and never at the cost of unreviewed major bumps.

**Red flags that you're about to violate this:**
- "npm itself is suggesting the --force command."
- "Getting vulnerabilities to zero is obviously the right outcome."
- "The breaking changes warning is boilerplate; it'll probably be fine."
- "I'll just run it and see if the tests still pass."
- "Security fixes justify whatever version changes they require."
