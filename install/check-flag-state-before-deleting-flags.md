### Check Flag State Before Deleting Feature Flags

NEVER remove a feature flag based on the age of the code. A flag is safe to delete only when its live state is verified: 100% enabled, for every customer, in every environment and region, with no targeting rules or opt-outs. That state lives in the flag system, not in the code, and you usually cannot see it.

Before removing any flag check:

- Ask the user for the flag's current state in the flag service or config: global percentage, per-customer overrides, per-region rules, and environment differences. If you cannot get this, do not remove the flag.
- Check which branch you'd be keeping. If the plan is to keep the "on" branch, confirm the flag is fully on; if any population is off, deleting the flag changes their product.
- Remember flags that are off everywhere: inlining the "on" branch for those launches a feature someone deliberately shelved. Verify the off branch isn't the real production behavior.
- Search for the flag name as a string across configs, infra code, experiment definitions, and docs — targeting rules and kill switches reference flags by name.
- When removal is verified safe, remove the flag, the dead branch, and the flag definition together, and say what evidence you relied on.

**Red flags that you're about to violate this:**
- "This flag is two years old, the rollout is obviously done."
- "The flag defaults to true, so everyone must have it on."
- "I'll keep the enabled path since that's clearly the intended behavior."
- "Stale flags are tech debt; removing them is always safe cleanup."
- "If some customer had this off, there'd be a comment saying so."
- "The feature shipped ages ago, the off branch can't matter."
