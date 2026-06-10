---
title: No Helpers for One Call Site
slug: no-helpers-for-one-call-site
category: scope
tags: [universal, scope, over-engineering]
works_with: all
severity: medium
one_liner: "AI extracting helper utilities for code that has exactly one caller"
---

# No Helpers for One Call Site

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from extracting single-use logic into utils files and helper functions nobody will ever call again.

**[Copy-paste ready version](../../install/no-helpers-for-one-call-site.md)** — just the instruction block, no explanation.

## The Problem

Somewhere in the feature you asked for, a timestamp needs formatting. Three lines would do it inline. Instead the AI creates `utils/dates.ts`, exports `formatRelativeTimestamp()`, writes a docstring describing its one use, and imports it back into the only file that will ever call it. Multiply by every small operation in the task and you get a constellation of tiny files, each existing to serve one line of the actual feature.

Assistants extract eagerly because "small functions" and "reusable utilities" are praised in the abstract, and a named helper feels like structure. But a helper with one caller is indirection with no payoff: the reader must jump to another file to learn what three lines would have said in place, the utils directory becomes a graveyard where near-duplicate helpers accumulate because nobody can find the existing ones, and the function's name becomes a tiny lie the moment the caller's needs drift.

Extraction is cheap to do later and expensive to undo. When a second caller actually appears, extracting the now-proven logic takes a minute. Until then, inline code is more readable, more greppable, and easier to delete.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No Helpers for One Call Site

Write logic inline at its only call site. NEVER extract a helper function, utility module, or shared file for code that one place uses.

The core problem: single-caller helpers add a file hop for every reader and seed a utils graveyard of near-duplicates, while real reuse, if it ever comes, makes extraction trivial at that point.

- A few lines of formatting, validation, or transformation used once belongs inline where it runs
- Do not create or add to `utils/`, `helpers/`, or `lib/` files as part of a feature unless the request asks for shared code
- Extraction is justified when a second caller exists in the same change, or when the logic is genuinely large enough to drown its containing function (think dozens of lines, not five)
- Extracting purely to give code a descriptive name is not justified; use a comment
- Before creating any new helper, check whether an equivalent one already exists in the project; duplicating an existing utility is worse than either option
- If you believe logic will be reused soon, write it inline and say so in one sentence; whoever adds the second caller can extract it with proof in hand

**Red flags that you're about to violate this:**
- "I'll pull this into a utility so it's reusable..."
- "This deserves its own well-named function..."
- "Other parts of the app will probably need this too..."
- "Small single-purpose functions are cleaner..."
- "I'll create a helpers file to keep the component lean..."
- "Extracting this makes the main function read like prose..."

---

## Why It Works

1. **It inverts the readability claim.** The AI believes extraction always improves readability; stating that a file hop costs more than three inline lines corrects the model for the single-caller case.

2. **It makes reuse falsifiable.** "Probably reused" justifies anything; "second caller exists in this change" is a fact the AI can check before extracting.

3. **It offers the comment as the naming outlet.** Much extraction is really a desire to label code. Permitting a comment satisfies that urge without the indirection.

4. **It defends against the graveyard.** Requiring a search for existing utilities first attacks the actual failure cycle: helpers nobody finds, so helpers get duplicated, so nobody can find anything.

## Origin

A review of a mid-sized web app found 41 functions under `src/utils/` with exactly one caller each, including three separate "truncate string with ellipsis" helpers written months apart, two of which handled multibyte characters differently. Most were traced to AI-assisted feature work. The team spent a sprint inlining or merging them; the diff deleted 19 files and made every affected feature shorter to read.
