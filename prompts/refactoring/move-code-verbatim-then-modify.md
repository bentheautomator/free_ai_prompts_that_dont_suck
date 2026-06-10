---
title: Move Code Verbatim, Then Modify
slug: move-code-verbatim-then-modify
category: refactoring
tags: [universal, refactoring]
works_with: all
severity: high
one_liner: "Stops moves and edits combined into one step where neither can be verified"
---

# Move Code Verbatim, Then Modify

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from relocating code and rewriting it in the same motion, so neither the move nor the edit can be checked.

**[Copy-paste ready version](../../install/move-code-verbatim-then-modify.md)** — just the instruction block, no explanation.

## The Problem

"Move this validation logic into its own module" should produce a diff where the deleted lines and the added lines match, and any reviewer can verify the move in thirty seconds. What assistants actually produce is a move-and-makeover: the code arrives at its new home renamed, restructured, "improved," and subtly different. Now the diff proves nothing. The reviewer can't confirm the move was faithful (the lines don't match) and can't evaluate the edits (they're camouflaged inside relocation noise). Any behavior change introduced during the makeover is structurally invisible, because there is no version anywhere that isolates it.

Models conflate the two operations because once code is "in hand" for the move, rewriting it costs nothing extra in generation, and arriving code that doesn't match the new module's style feels unfinished. But move and modify have opposite verification stories: a verbatim move is checkable by diff symmetry alone, and a modification of in-place code is checkable by a focused diff. Combined, they're checkable by nothing.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Move Code Verbatim, Then Modify

Moving code and changing code are two different steps. ALWAYS move first, verbatim, and verify; modify afterward, in place, as a separate change. NEVER rewrite code "in flight" between its old location and its new one.

A verbatim move is verifiable by inspection: deleted lines equal added lines. A move-with-makeover is verifiable by nothing.

- Step 1, move: cut the code and paste it into its new location byte-for-byte: same names, same structure, same comments, same formatting, even the parts you intend to change next. The only permitted edits are the mechanical ones the new location forces: import paths, module-qualified references, visibility keywords.
- Verify the move: the code compiles, tests pass, and the deleted block and added block are textually identical apart from those forced mechanical edits, which you can enumerate.
- Step 2, modify: now improve the code in its new home (rename, restructure, restyle to match the module) as its own change with its own focused diff.
- This ordering also keeps history useful: many tools track verbatim moves and preserve blame across them; a rewritten move severs the line-level history at exactly the moment the code is hardest to recognize.
- The same discipline applies in miniature to moving a function within a file, lifting a block into a helper, or hoisting code between layers: relocate exactly, confirm, then change.
- If verbatim arrival truly cannot compile in the new location (name collisions, circular imports), make the minimum forced adaptation, and list each forced edit explicitly so the reviewer can subtract them from the diff.

**Red flags that you're about to violate this:**

- "While moving this, I'll adapt it to the new module's conventions."
- "No point pasting it as-is when I already know what needs fixing."
- "I'll rename it during the move; it's one less diff."
- "Moving it verbatim would leave the new file temporarily inconsistent."
- "The cleanup is small enough to fold into the relocation."

---

## Why It Works

1. **It gives each step a verification story and shows the combination has none.** "Deleted lines equal added lines" is a concrete check the model can run on its own diff; understanding that the combined operation destroys both checks supplies the reason, not just the rule.
2. **The forced-edits enumeration handles reality without opening the door.** Imports genuinely must change during a move; bounding the exception to listable, mechanical edits keeps "adaptation" from expanding into rewriting.
3. **The temporarily-inconsistent state is pre-authorized.** The model rewrites in flight partly because verbatim-moved code clashes with its new surroundings; declaring that clash a correct intermediate state removes the aesthetic pressure that drives the violation.

## Origin

Asked to move session-token validation from a controller into a shared auth module, an assistant relocated it with improvements: cleaner structure, better names, and an inverted guard clause that flipped one early return. The diff showed 80 deleted lines and 60 different added lines; the move was unreviewable as a move, so it was reviewed as new code, lightly. The inverted guard let expired-but-well-formed tokens through one endpoint for a month, until a pen test found what the diff format had hidden.
