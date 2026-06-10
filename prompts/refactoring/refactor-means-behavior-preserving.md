---
title: Refactor Means Behavior-Preserving
slug: refactor-means-behavior-preserving
category: refactoring
tags: [universal, refactoring]
works_with: all
severity: critical
one_liner: "Stops behavior changes smuggled into changes labeled as refactors"
---

# Refactor Means Behavior-Preserving

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from changing what code does while claiming to only change how it's shaped.

**[Copy-paste ready version](../../install/refactor-means-behavior-preserving.md)** — just the instruction block, no explanation.

## The Problem

The word "refactor" has a precise meaning: change the structure of code without changing its observable behavior. AI assistants treat it as a synonym for "improve," which is a much bigger word. Asked to refactor a date-parsing function, an assistant will restructure it and, while it's in there, make the parser stricter, normalize the return value, and start raising on inputs the old code tolerated. The diff is labeled "refactor: clean up date parsing." It is actually three behavior changes wearing a refactor's name tag.

This happens because the model evaluates code against an internal notion of what it *should* do, not what it *does* do. When the two differ, the model quietly sides with "should." But callers were built against "does." Every silent improvement is a contract change nobody agreed to, hidden inside a diff that reviewers were told was safe to skim.

The damage compounds because refactor-labeled changes get lighter review. That's the whole social contract of the label: structure only, behavior identical, safe to approve quickly. An assistant that breaks that contract poisons it for every future change.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Refactor Means Behavior-Preserving

When a task is described as a refactor, the observable behavior of the code MUST be identical before and after: same outputs for the same inputs, same side effects, same errors, same edge-case handling. "Refactor" means changing shape, never meaning.

The temptation is to improve behavior while restructuring, because the old behavior looks wrong. Resist it: callers depend on what the code does, not on what it should do.

- Preserve behavior bug-for-bug. If the old code returns `None` for empty input instead of raising, the new code returns `None` for empty input. Oddness is not permission.
- Preserve the full input domain. Inputs the old code accepted (trailing whitespace, mixed case, legacy formats) must still be accepted, even if accepting them seems sloppy.
- Preserve outputs exactly: same types, same rounding, same ordering where callers could observe it, same `null` vs missing-field distinctions.
- If you believe the current behavior is a bug, finish the behavior-preserving refactor first, then report the suspected bug separately and ask whether to fix it. Never bundle the fix in.
- If a structural change you want is impossible without changing behavior, stop and say exactly which behavior would change and why, and wait for approval.
- Describe your change honestly. If any behavior changed, the change is not a refactor and must not be labeled as one.

**Red flags that you're about to violate this:**

- "While restructuring this, I should also make it handle this case correctly."
- "The old behavior here is clearly a bug, so I'll fix it in passing."
- "No reasonable caller depends on this quirk."
- "Returning an empty list is better than returning None anyway."
- "I'll tighten up the validation since I'm rewriting this function."

---

## Why It Works

1. **It reframes the word itself.** The model's working definition of "refactor" is "make better"; the instruction replaces it with the actual definition, "same behavior, different shape," which changes what the model optimizes for.
2. **"Bug-for-bug" closes the biggest loophole.** Most smuggled changes are justified internally as bug fixes. Stating that even bugs must survive a refactor removes the one excuse the model reaches for first.
3. **The separate-report channel preserves the upside.** The model often does spot real bugs. Giving those observations a legitimate exit (report, don't fix) means the rule doesn't fight the model's usefulness, just its bundling.

## Origin

An assistant was asked to refactor a coupon-validation function for readability. It restructured the function and, unprompted, changed case-insensitive coupon matching to exact matching because "codes should be canonical." Every coupon typed in lowercase stopped working at checkout. Support tickets, not tests, found it, four days and one marketing campaign later.
