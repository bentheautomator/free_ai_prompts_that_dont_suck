---
title: Give Every Feature Flag an Expiry
slug: give-every-feature-flag-an-expiry
category: configuration
tags: [universal, config, feature-flags]
works_with: all
severity: medium
one_liner: "Stops feature flags from outliving their rollout and fossilizing into debt"
---

# Give Every Feature Flag an Expiry

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from adding permanent-by-default feature flags and from treating long-dead flags as load-bearing configuration.

**[Copy-paste ready version](../../install/give-every-feature-flag-an-expiry.md)** — just the instruction block, no explanation.

## The Problem

A feature flag is supposed to be scaffolding: it guards a rollout, the rollout finishes, the flag comes down. In practice, the AI adds `ENABLE_NEW_CHECKOUT` for a safe launch, the launch succeeds, and the flag stays at 100% forever. Six months later there are forty flags, thirty-five of them permanently on or permanently off, each one doubling the number of theoretical code paths and each one a landmine — flip the wrong "obviously dead" flag and you resurrect a code path nobody has run since two refactors ago.

AI assistants make this worse from both directions. They add flags eagerly (flagging is the responsible-looking choice) and remove them never (removal isn't part of any task they're given). Worse, when working in flag-littered code, they faithfully preserve both branches of every dead flag — refactoring, testing, and extending code that hasn't executed in a year, because nothing in the source says the flag is settled.

The cost isn't hypothetical. Dead flags have shipped wrong branches when a config store reset to defaults, and stale "off" branches have hidden bugs that surface the day someone flips a flag to debug something else.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

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

---

## Why It Works

1. **It attaches a death certificate at birth.** Flags accumulate because removal has no trigger; a written exit condition turns "someday" into a checkable predicate.
2. **It makes flag deletion an in-scope action.** The AI defaults to preserving every branch it sees; explicit permission to propose removal converts dead-code maintenance into dead-code cleanup.
3. **It distinguishes rollout flags from operational toggles**, so the rule can be strict without forcing kill switches to justify their existence every sprint.
4. **It requires whole-flag removal**, preventing the half-removed state — branch gone, config key still set in three environments — that confuses every future reader.

## Origin

A team's config store was rebuilt during an infrastructure migration and every flag reverted to its declared default. Thirty-one flags were "temporarily" at non-default values, some for over two years. The reverts re-enabled a deprecated pricing calculation whose off-branch had been the real code path since the previous spring. Invoices went out computed by logic everyone believed deleted. The postmortem's first action item: every flag gets an owner and an expiry, enforced at declaration.
