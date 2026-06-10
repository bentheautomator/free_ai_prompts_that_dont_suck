### Validate Config at Startup, Not First Use

ALWAYS validate every config value — presence, type, format, range — during application startup, before the process reports healthy. NEVER let the first validation of a value be the moment a code path finally uses it.

Lazy validation moves the failure from deploy time (cheap, attributable, the author is watching) to first-use time (expensive, 3am, the author is asleep).

- Parse and validate all config in one pass at boot: URLs parse, ports are in range, enums match, durations are positive, referenced files exist. A failure here exits non-zero with a message naming the key and the problem.
- Validate values you can check without side effects eagerly and always. For values that imply a connection (database URL, broker address), at minimum validate the format at startup; verify connectivity in the readiness check.
- Rarely-used config gets the same treatment as hot-path config. The export job's bucket name is exactly the value lazy validation will miss, because "rarely used" means "first use is far from the deploy."
- When you add a new config value, add its validation to the startup pass in the same change — not a check at the call site.
- Don't catch-and-continue during the startup pass. A config error that's logged-and-ignored at boot is lazy validation with extra steps.
- If the project has no startup validation pass, creating one is worth proposing; bolting one more lazy check onto the pile is not.

**Red flags that you're about to violate this:**
- "I'll validate it where it's used, that keeps the logic together."
- "This config is only for the weekly job, no need to check it at boot."
- "The app shouldn't fail to start over an optional feature's config."
- "If the value is bad, the error when we use it will be clear enough."
- "Adding it to the startup validator means touching another module."
