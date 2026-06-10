---
title: Verify Constraints Before Planning Around Them
slug: verify-constraints-before-planning-around-them
category: planning
tags: [universal, planning]
works_with: all
severity: medium
one_liner: "Elaborate workarounds for a limitation that doesn't exist"
---

# Verify Constraints Before Planning Around Them

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents designing around imagined limitations instead of checking whether they're real.

**[Copy-paste ready version](../../install/verify-constraints-before-planning-around-them.md)** — just the instruction block, no explanation.

## The Problem

Plans warp around constraints, so a false constraint warps the whole plan. The assistant decides — from training-data vintage, from a vaguely remembered limitation, from how things usually work — that "the ORM can't do window functions," or "the framework doesn't support streaming responses," or "we can't change that table." Then it builds the workaround: raw SQL with hand-rolled escaping, a polling layer, a parallel shadow table. The workaround is often substantial, clever engineering. In service of a wall that was never there.

Imagined constraints are worse than imagined capabilities, because they fail silently. If you assume a capability that doesn't exist, the code breaks and tells you. If you assume a constraint that doesn't exist, everything works — you just shipped the complicated version, permanently, and the complexity gets inherited by everyone who touches that code after you. Nobody ever gets an error message saying "this workaround was unnecessary."

The tell is sourcing. Real constraints have evidence: a doc link, an error message you actually got, a version number you actually checked. Imagined constraints have vibes: "typically," "as far as I know," "last I checked." Any constraint that materially shapes the plan deserves two minutes of verification against this codebase, this version, this configuration.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Verify Constraints Before Planning Around Them

NEVER let an unverified constraint shape the plan. Before designing a workaround, prove the wall exists — in this codebase, this version, this configuration — not in your general recollection of how such things usually work.

The core problem: a false capability fails loudly when the code breaks; a false constraint fails silently, because the unnecessary workaround works fine and merely ships permanent complexity.

- When you notice a constraint steering your design ("can't use X, so I'll..."), stop and source it: check the installed version's docs, read the actual config, run a two-line probe.
- Version-check your knowledge. "The library doesn't support that" frequently means "didn't support that several releases before the version in this lockfile."
- Distinguish constraint types: technical ("the API has no batch endpoint") gets verified by docs or a test call; policy ("we're not allowed to touch that schema") gets verified by asking the user. Don't guess at either.
- In the plan, mark each load-bearing constraint with how you verified it. "Workaround for X (confirmed: see CHANGELOG 4.2)" versus silence is the difference between engineering and folklore.
- If verification kills the constraint, delete the workaround from the plan entirely — don't keep it as "safer anyway."

**Red flags that you're about to violate this:**
- "As far as I know, the framework can't..."
- "Typically these APIs don't allow..."
- "I remember this being a limitation..."
- "We probably can't modify that, so I'll build around it..."
- "Even if it does support it, the workaround is safer..." (it's just more code)

---

## Why It Works

1. **It targets the silent failure mode.** Code reviews and tests catch wrong code; nothing downstream catches unnecessary code that works. Verification at plan time is the only checkpoint this failure ever passes through.

2. **It attacks knowledge staleness directly.** An assistant's picture of a library is frozen at training time; the lockfile is current. The version-check rule routes the question to the artifact that's actually right.

3. **It makes constraints auditable.** "Confirmed via X" annotations let the user challenge the load-bearing assumptions of a plan at review time, instead of discovering years later that a subsystem's complexity traces back to a rumor.

## Origin

A service grew a hand-built job queue — polling table, locking columns, a worker loop, about 600 lines — because "the managed queue we use doesn't support delayed delivery." It had supported delayed delivery since a release that predated the project. The two-minute docs check happened eighteen months later, during an incident in the hand-built locking logic, when a new engineer asked why the feature existed at all. The migration off the workaround took a week; the original wall had never existed for a single day of the project's life.
