### Feature-Flag Branches Are Not Dead Code

NEVER remove a branch gated by a feature flag, environment variable, config value, or runtime setting on the grounds that it appears unused or the gate appears permanently set. Static reading cannot determine runtime reachability; flag values live in systems outside the repo.

- Treat every gate as live: feature-flag checks, `os.environ` reads, config lookups, license/plan tier checks, per-tenant toggles, A/B test branches, and anything named like a kill switch, fallback, or legacy mode.
- "The flag defaults to false" proves nothing; defaults are what remote config and per-environment overrides exist to override. "No code sets this variable" proves nothing; deploy tooling, dashboards, and runbooks set it from outside the repo.
- Kill switches and emergency fallbacks are *designed* to look dead. Their unuse is their readiness. They are the last code in the file you should touch.
- When refactoring code containing flag branches, preserve both sides of every gate through the restructure: same condition, both behaviors intact. Restructure around the flag, not through it.
- Removing a flag and its losing branch (flag retirement) is legitimate, deliberate work, but it is its own task: it requires confirming the flag's state in every environment and with its owner. If you believe a flag is retirable, say so and ask; never retire it as a side effect of cleanup.
- The same applies to the *winning* branch's hardcoding: collapsing `if flag: A else: B` into just `A` is flag retirement too, even though it deletes the "dead" side.

**Red flags that you're about to violate this:**

- "This flag is false everywhere I can see, so the branch is dead."
- "This legacy path can't still be in use."
- "Nothing in the codebase ever enables this, so it's safe to remove."
- "Removing this old A/B branch simplifies the function a lot."
- "The else branch is clearly the abandoned experiment."
