---
title: Carry Comments Through Rewrites
slug: carry-comments-through-rewrites
category: refactoring
tags: [universal, refactoring]
works_with: all
severity: high
one_liner: "Stops refactors from silently dropping comments, docstrings, and TODOs"
---

# Carry Comments Through Rewrites

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from discarding comments, docstrings, and annotations when it restructures the code they were attached to.

**[Copy-paste ready version](../../install/carry-comments-through-rewrites.md)** — just the instruction block, no explanation.

## The Problem

When an assistant restructures a function, the code gets regenerated and the comments mostly don't. The docstring with the example invocations, the `# DO NOT change this order, see incident retro 2023-04` warning, the link to the vendor doc explaining the weird pagination, the `TODO(maria): remove after migration` marker: all of it tends to evaporate, because the model rebuilds the logic from its understanding of the logic, and comments aren't logic. What ships is code that works identically and a file that knows nothing about itself anymore.

This is a quiet form of data loss. Comments are the only place a codebase stores *why*, and unlike behavior, there's no test that fails when the why disappears. The model also has an active bias here: it has read a thousand style guides saying good code needs no comments, so dropping them can feel like part of the cleanup. Six months later someone reorders the lines the deleted warning was guarding, and the incident from the retro gets a sequel.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Carry Comments Through Rewrites

When refactoring, comments, docstrings, and annotations are part of the code. ALWAYS carry them into the restructured version, attached to whatever the relevant logic became. NEVER drop a comment because the code around it changed shape.

Comments are the only record of *why*; deleting one is deleting institutional memory with no test to catch it.

- Before restructuring a region, inventory its comments: docstrings, inline comments, block comments above functions, TODO/FIXME/HACK markers, lint suppressions with explanations, and links to issues, docs, or incidents.
- After restructuring, account for every item: it moved with its logic, was updated to match the new shape, or became genuinely false and was removed deliberately. State removals in your summary with the reason.
- When code moves into a new function, its comments move too. When one function splits into three, the docstring's content gets distributed, not deleted.
- Update stale references in surviving comments ("see `parse_row` above" must track the rename), because a wrong comment is worse than a missing one.
- Warnings are sacred: anything saying "do not", "must", "careful", "ordering matters", or naming an incident or ticket survives every rewrite, verbatim if possible.
- "Good code is self-documenting" applies to comments that restate *what*. Comments that record *why*, external constraints, or history can never be expressed by clearer code, so cleaner code is not a reason to drop them.
- Do not replace specific comments with generic regenerated ones. A docstring listing two real edge cases is worth more than three paragraphs of plausible boilerplate.

**Red flags that you're about to violate this:**

- "The restructured code is clear enough not to need these comments."
- "I'll write a fresh docstring; the old one was out of date anyway."
- "This TODO is ancient; it can't still be relevant."
- "That comment refers to code that doesn't exist in my version."
- "Comments explaining workarounds are clutter once the code is clean."

---

## Why It Works

1. **It reclassifies comments from decoration to payload.** The model treats behavior as the thing to preserve and comments as packaging; declaring them part of the code puts them inside the behavior-preservation contract.
2. **The inventory-and-account step makes loss detectable.** Comments vanish silently because nothing counts them; a before/after accounting turns each disappearance into an explicit decision the model must defend.
3. **The what/why distinction disarms the style-guide reflex.** The model's "self-documenting code" training is real but only applies to *what*-comments; giving it that precise carve-out lets it keep the reflex without destroying the *why*.
4. **Banning regenerated boilerplate closes the substitution loophole.** Otherwise the model "preserves documentation" by replacing hard-won specifics with fluent generalities, which scores as compliance while losing everything that mattered.

## Origin

A refactor of a data-export pipeline dropped a one-line comment: `# flush before rename, NFS caches dirents, see ops ticket`. The restructured code happened to keep the right order, so nothing broke, until a later change reordered the calls, which the comment would have stopped. Exports silently wrote zero-byte files on one storage backend for a week. The ops ticket explaining everything had been findable the entire time, linked from a comment that no longer existed.
