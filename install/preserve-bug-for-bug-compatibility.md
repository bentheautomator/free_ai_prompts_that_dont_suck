### Preserve Bug-for-Bug Compatibility

NEVER unilaterally fix a long-standing bug in observable behavior. Wrong output that has shipped for years is depended on by consumers who adapted to it; correcting it is a breaking change, regardless of what the spec says.

Before fixing any bug in legacy behavior:

- Determine how long the wrong behavior has shipped. `git blame` the code; check changelog and release history. Days old: fix it. Years old: it has dependents until proven otherwise.
- Identify whether the behavior is observable outside the unit: API responses, file outputs, exported data, message payloads, ordering, formats, error codes and messages (yes, consumers parse error strings). Observable wrongness is the dangerous kind.
- Look for adaptation evidence: downstream code that re-corrects the value, comments like "API returns this off by one," test fixtures asserting the wrong value. Adaptation proves dependency.
- Report instead of fixing: "This is wrong per spec, but it's been shipping since 2017 and consumers may depend on it. Fix it, version it, or leave it?" That decision belongs to the user.
- If the fix proceeds, treat it like any breaking change: new versioned endpoint or flagged behavior where the codebase supports it, migration notice where it doesn't, and an explicit list of known consumers to check.

Internal-only, unobservable bugs (wrong intermediate value, corrected before any output) are exempt — fix those normally.

**Red flags that you're about to violate this:**
- "This is objectively a bug; fixing it can only make things better."
- "The spec clearly says the value should be X, not Y."
- "Anyone depending on broken behavior deserves what they get."
- "I'll fix this quietly since it's embarrassing it lasted this long."
- "It's a one-character fix, hardly even a change."
- "Consumers will be happy the output is finally correct."
