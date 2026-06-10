---
title: One Module Per Refactoring Pass
slug: one-module-per-refactoring-pass
category: refactoring
tags: [universal, refactoring]
works_with: all
severity: high
one_liner: "Stops refactors that sprawl across module boundaries in a single pass"
---

# One Module Per Refactoring Pass

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from refactoring multiple modules in one sweep, producing a cross-cutting diff where nothing can be verified or reverted independently.

**[Copy-paste ready version](../../install/one-module-per-refactoring-pass.md)** — just the instruction block, no explanation.

## The Problem

Refactors spread. The assistant starts extracting a helper in the orders module, notices the payments module has a similar pattern, "fixes" that too, then adjusts the shared utils module both of them import, and twenty minutes later the diff spans four modules and thirty files. Each individual edit might even be reasonable. Together they form a change with no seams: it can't be reviewed module by module, can't be reverted without reverting everything, and when a test fails, the failure could have come from any of four restructurings.

Models sprawl like this because they pattern-match. Once "extract duplicated validation" is the active idea, every file in context that contains duplicated validation becomes a target, and the model has no internal cost function for diff radius. Humans stop at module boundaries because they know each boundary is a review boundary, a deploy boundary, and an ownership boundary. The model just sees more matching text.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### One Module Per Refactoring Pass

Confine each refactoring pass to a single module (one package, one directory, one service). NEVER restructure multiple modules in the same change, even when they share the same smell.

A multi-module refactor has no seams: it can't be reviewed, bisected, or reverted in parts, and a failure anywhere implicates everywhere.

- Pick the target module before starting and name it. Every edited file should live inside it.
- Edits outside the target are allowed only when mechanically forced by the refactor (a caller in another module must follow a changed internal interface) and must be the minimum such edit, not an opportunity to clean that module up too.
- When you spot the same problem in a second module, do not fix it there. Add it to a list and present the list at the end: "the same duplication exists in payments and shipping; want me to do those next, separately?"
- Shared code (utils, common, core) is its own module and the highest-risk target, because everything depends on it. Refactor it alone, in its own pass, never as a side effect of refactoring a consumer.
- Sequence multi-module work as separate passes with verification between them: finish module A, run the tests, get it reviewed or committed, then start module B.
- If a refactor cannot be expressed within one module plus mechanical caller updates, it is an architectural change, not a refactor; stop and say so.

**Red flags that you're about to violate this:**

- "The payments module has the exact same pattern; I'll fix it while I'm at it."
- "It's more consistent to apply this change everywhere at once."
- "These modules are so intertwined that I have to do them together."
- "I'll just quickly align the utils module with the new structure too."
- "Doing them one at a time means three reviews instead of one."

---

## Why It Works

1. **It gives the sprawl a queue instead of a wall.** The model's pattern-matching urge ("same smell over there") gets a sanctioned outlet, the follow-up list, so compliance doesn't require suppressing the observation, only deferring the edit.
2. **Naming the target module up front creates a checkable boundary.** "Files outside the target" is a mechanical test the model can apply to its own diff, unlike "keep the change focused."
3. **It singles out shared code as a separate pass.** Utils-module drive-bys are the most common and most damaging form of sprawl, because every consumer inherits the risk; an explicit rule for them blocks the worst case specifically.
4. **Verification between passes turns one big bet into several small ones.** A failure after pass two implicates pass two, restoring the bisectability that a single sweep destroys.

## Origin

A request to "clean up the duplication in the notifications module" produced a diff touching notifications, users, billing, and the shared utils package, because the assistant found the same duplication pattern everywhere. A test failure in billing blocked the whole change; nobody could approve a four-module diff to fix a one-module problem, and the entire branch was abandoned. The notifications cleanup, redone alone the next day, was 80 lines and merged before lunch.
