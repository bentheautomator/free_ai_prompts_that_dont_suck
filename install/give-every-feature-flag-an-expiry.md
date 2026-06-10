### Give Every Feature Flag an Expiry

NEVER add a feature flag without a written removal condition, and NEVER preserve a flag that has met one. Flags are scaffolding, not architecture.

A flag at 100% (or 0%) for months isn't configuration — it's two codebases pretending to be one.

- When adding a flag, record its exit criteria where flags are declared: a comment or metadata field with owner, purpose, and removal condition ("remove after checkout v2 is at 100% for two weeks").
- Default new flags to temporary. If someone wants a permanent operational toggle (kill switch, tenant entitlement), that's a deliberate, labeled exception — say so explicitly.
- When you touch code guarded by a flag that is clearly settled (hardcoded on, 100% everywhere, off-branch unreferenced for months), propose deleting the flag and the dead branch as part of the change, not preserving both sides.
- When removing a flag, remove all of it: the declaration, the config entries in every environment, both code branches, and the tests that only exercised the dead branch.
- Don't write new logic inside a dead flag's off-branch. If you're not sure a flag is dead, ask; don't split the difference by updating both branches.

**Red flags that you're about to violate this:**
- "I'll keep both branches just in case someone flips it back."
- "Removing the flag is out of scope for this ticket."
- "It's safer to leave it — it's only a config entry."
- "I'll add the flag now and we can decide the rollout plan later."
- "The off-branch still compiles, so it's fine to keep maintaining it."
