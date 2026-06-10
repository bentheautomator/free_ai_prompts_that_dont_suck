---
title: Check Flag State Before Deleting Feature Flags
slug: check-flag-state-before-deleting-flags
category: legacy-code
tags: [universal, legacy]
works_with: all
severity: critical
one_liner: "Blocks flag removal that force-enables features customers still have off"
---

# Check Flag State Before Deleting Feature Flags

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from deleting an old feature flag and inlining the "on" branch while real customers still run with the flag off.

**[Copy-paste ready version](../../install/check-flag-state-before-deleting-flags.md)** — just the instruction block, no explanation.

## The Problem

Feature flag cleanup has a default move: delete the flag check, keep the enabled branch, remove the disabled branch. It's the right move for a flag that's been at 100% for months. An AI assistant applies it to every old flag it meets, because an old flag reads as a finished rollout someone forgot to sweep up. But the flag's age says nothing about its state. Plenty of old flags are old *because* they're load-bearing: the rollout stalled at 80% over a performance regression, three enterprise customers are contractually opted out, one region is excluded for compliance, or the feature was quietly turned off after launch and nobody removed the code.

Deleting such a flag doesn't clean up a finished rollout — it force-enables the feature for exactly the population that had it off, which is the population with documented reasons. The diff looks like textbook hygiene. The incident looks like "why did feature X turn on for the customer who threatened to churn over feature X."

The state that decides whether removal is safe lives in the flag service, the database, or the config system — places the AI usually can't see and rarely thinks to ask about. Code age is the proxy it uses instead, and it's a terrible proxy.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

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

---

## Why It Works

1. **It relocates the truth.** The AI's instinct is to read the code for the answer; the instruction states flatly that the answer lives in the flag system, making "I checked the code" insufficient by definition.
2. **It enumerates the stall states** — partial rollouts, opt-outs, regional exclusions, shelved features — so "old flag" stops collapsing into "finished flag."
3. **The "which branch survives" question forces the dangerous case into view:** keeping the on-branch of a not-fully-on flag is a product change for someone, and phrasing it that way makes the AI notice.
4. **Verified removal stays cheap.** The rule doesn't protect flags forever; it prices removal at one question to the user, which is low enough that the rule actually gets followed.

## Origin

During a debt-reduction week, an assistant swept eleven "stale" flags from a billing service, inlining the enabled branches. Ten were genuinely done. The eleventh was held at 95% because the new invoice calculation rounded differently, and the remaining 5% were enterprise accounts whose contracts specified the old rounding. The first re-issued invoice discrepancy escalated to legal within a week. The flag had been old precisely because those five percent could never be migrated, which was documented — in the flag service's description field, where no one editing code would ever see it.
