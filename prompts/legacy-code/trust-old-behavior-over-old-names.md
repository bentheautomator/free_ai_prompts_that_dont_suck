---
title: Trust Old Behavior Over Old Names
slug: trust-old-behavior-over-old-names
category: legacy-code
tags: [universal, legacy]
works_with: all
severity: high
one_liner: "Stops refactors that trust stale names and comments over actual behavior"
---

# Trust Old Behavior Over Old Names

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from changing legacy code based on what its names and comments claim it does, instead of what it actually does.

**[Copy-paste ready version](../../install/trust-old-behavior-over-old-names.md)** — just the instruction block, no explanation.

## The Problem

In old code, names and comments are historical fiction. `validateEmail()` started out validating emails; over a decade it accreted normalization, an audit-log write, and a side effect that backfills a CRM field. The docstring still says "Returns true if the email is valid" because docstrings don't fail tests when they go stale. A comment that says "temporary cache, cleared hourly" describes an architecture from three redesigns ago.

AI assistants lean heavily on names and comments because that's how language models read code: identifiers are dense semantic signals, and trusting them is usually efficient. In legacy code it's a trap. An assistant that "knows" what `validateEmail` does — because the name said so — will happily replace a call to it with an inline regex, deleting the audit write and the CRM backfill it never knew existed. Or it will reorganize callers around the documented null-return that is actually a throw, and has been a throw since 2015.

The wreckage is quiet: nothing about the diff looks wrong, because the diff is consistent with the names. It's only inconsistent with the behavior, which nobody read.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Trust Old Behavior Over Old Names

NEVER act on what legacy code is called or what its comments claim. Names and comments record what code did when they were written; the code records what it does now. When they disagree, the code is right and the prose is a fossil.

Before changing legacy code or its callers:

- Read the implementation, not just the signature. Trace what the function actually returns, throws, mutates, writes, and logs. Side effects accumulated after naming are the most common surprise.
- Verify documented contracts against the code: "returns null on failure" must be checked against the actual failure path, because callers may already depend on the real (undocumented) behavior.
- Treat name-based substitution as high risk: replacing a call to `parseDate()` with a library call assumes the legacy function only parses dates. Confirm that assumption by reading it.
- When you find a name/behavior mismatch, do not "fix" the behavior to match the name — callers depend on the behavior, not the name. Report the mismatch instead; renaming or correcting is the user's call.
- Apply the same skepticism to your summaries: describe what the code does, not what it's named. "Calls validateEmail, which also writes an audit record" beats "validates the email."

The freshness rule: behavior is verified every execution; names were verified once, possibly before you were trained.

**Red flags that you're about to violate this:**
- "The function name makes it obvious what this does."
- "The docstring documents the contract, so I can rely on it."
- "This helper just formats a string; I can inline it."
- "The comment explains the design, no need to trace the code."
- "I'll make the code do what its name says it should."
- "A function called isValid couldn't possibly have side effects."

---

## Why It Works

1. **It assigns a freshness hierarchy.** Code is re-validated by every production run; prose was validated once at write time. Making the AI rank evidence by staleness flips its default trust order in exactly the legacy cases where the defaults fail.
2. **It targets substitution, the highest-risk move.** Replacing or inlining a call is where name-trust does maximum damage, because every undocumented side effect is silently deleted in one step.
3. **The "don't fix toward the name" clause blocks the subtle inverse failure:** an AI that discovers the mismatch and resolves it by changing behavior breaks callers just as hard as one that never noticed.
4. **Behavior-accurate summaries propagate the correction** to the human in the loop, who is usually trusting the same stale names the AI was.

## Origin

A cleanup task replaced calls to a crusty internal `formatCurrency()` with a standard locale-aware formatter — a one-line improvement, by the name of it. The legacy function also rounded using the half-even banker's rounding required by the company's payment processor agreement, a detail present in the code and absent from the name, comment, and docs. The standard formatter rounded half-up. Settlement reports drifted from processor statements by a few cents per thousand transactions, which took an accountant most of a quarter-end week to trace back to a refactor that "just swapped a formatting call."
