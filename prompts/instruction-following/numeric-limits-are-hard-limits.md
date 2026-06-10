---
title: Numeric Limits Are Hard Limits
slug: numeric-limits-are-hard-limits
category: instruction-following
tags: [universal, rules, constraints]
works_with: all
severity: medium
one_liner: "Keep it under 50 lines treated as keep it under 50-ish"
---

# Numeric Limits Are Hard Limits

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents numeric rules — line limits, file counts, size budgets — from being treated as soft targets to land near.

**[Copy-paste ready version](../../install/numeric-limits-are-hard-limits.md)** — just the instruction block, no explanation.

## The Problem

You set a limit: functions under 50 lines, PRs under 400 lines, summaries under 200 words, no more than 3 new files. The AI delivers a 68-line function, a 540-line PR, a 280-word summary, 5 new files — and describes each as compliant, or close enough not to mention. Numbers in your rules are being read as the center of an acceptable range rather than its edge. "Under 50" gets processed like "around 50," which in practice means "under 50 unless the content wants more," which means nothing.

The drift has a mechanical cause: the model generates content first and measures never. There's no counting step — the limit is consulted as a vibe during generation ("keep this shortish") and the result lands wherever the content's natural size was. And limit violations ratchet: a 68-line function that passed becomes the implicit precedent for an 80-line one. The user's number meant something — a review threshold, a CI gate, a UI truncation point, a context budget. Land at 110% of it and the gate fails anyway; the rule consumed effort and delivered nothing.

If overshooting by 30% were fine, the user would have written the bigger number.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Numeric Limits Are Hard Limits

A numeric limit is an EDGE, not a target. "Under 50 lines" means 50 is already too many — NEVER treat the number as the center of an acceptable range.

**The core problem:** You generate content at its natural size and consult the limit as a vibe, never actually counting. The result lands wherever it lands, you call it compliant, and each overshoot becomes precedent for a bigger one. The user's number encodes a real threshold — a CI gate, a truncation point, a budget — and 110% of it fails the same as 200%.

**Do this:**

- COUNT before delivering: lines, words, files, items — measured, not estimated; if you can't measure, say the value is unverified
- When the content genuinely won't fit the limit, restructure to fit (split the function, trim the summary, stage the PR) — fitting is the work, not an inconvenience around it
- If fitting would truly damage the result, present the conflict BEFORE exceeding: "This wants ~80 lines; the limit is 50. Split it, or approve the overage?"
- Hold limits steady all session: the limit on your tenth function is the same as on your first, regardless of what's been let slide

**Do not:**

- Round in your own favor ("57 is basically 50")
- Treat past overshoots as the new baseline
- Report compliance with a limit you didn't measure against
- Exceed first and justify after — approval comes before the overage, or the overage doesn't happen

**Red flags that you're about to violate this:**

- "That's roughly within the limit"
- "The limit is clearly approximate"
- "A few lines over won't matter"
- "This content naturally needs more room, so the limit flexes"
- "I'll deliver it slightly over and note that it ran long"

---

## Why It Works

1. **It inserts the missing measurement step.** Violations happen because nothing ever counts. Making delivery conditional on an actual measurement converts the limit from a generation-time vibe into a checkable gate — the single change that makes every other part enforceable.

2. **It redefines fitting as the task.** Models treat the content's natural size as fixed and the limit as negotiable. "Restructure to fit — fitting is the work" reverses the polarity: the limit is fixed, and the content adapts.

3. **It blocks the ratchet.** Each tolerated overshoot rebases the limit. Pinning the tenth function to the same number as the first cuts the precedent chain that turns 50 into 80 over a session.

4. **It orders approval before overage.** "Exceed and explain" puts the user in the position of rejecting finished work, which they rarely do. Requiring the conflict to surface *before* the limit is crossed keeps the decision real.

## Origin

A team's rules capped PRs at 400 changed lines because their review tooling auto-assigned a second reviewer above that threshold — a compliance requirement, not a preference. Their assistant delivered a "complete" refactor at 612 lines, noting cheerfully that it had "kept the change focused." The PR sat for four days while the second-reviewer requirement nobody had staffed for blocked the merge, and it was ultimately split into two PRs anyway — by hand, after the fact, which took longer than splitting it up front would have. The number in the rules file had never been approximate. It was the exact integer at which the process changed shape.
