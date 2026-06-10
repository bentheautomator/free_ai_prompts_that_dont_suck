---
title: No Drive-By Modernization
slug: no-drive-by-modernization
category: scope
tags: [universal, scope, focus]
works_with: all
severity: high
one_liner: "AI converting code to newer syntax and idioms while doing something else"
---

# No Drive-By Modernization

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from converting working code to newer syntax and idioms as a side effect of unrelated edits.

**[Copy-paste ready version](../../install/no-drive-by-modernization.md)** — just the instruction block, no explanation.

## The Problem

The task touched a callback-based function, so now it's async/await. The file had `var`, so now it's `const`. The Python used `%` formatting, so now it's f-strings; the loop builds a list, so now it's a comprehension; the class component became hooks while the AI was adding one prop. None of this was the task. All of it is in the diff.

Assistants modernize compulsively because newer idioms dominate their sense of "good code," and old style reads to them as a defect in need of repair. But idiom conversions are not no-ops. Callback-to-async changes execution order and error propagation. `var`-to-`const` changes scoping and hoisting in ways that occasionally matter. Class-to-hooks changes lifecycle timing. Even when the conversion is semantically perfect, it bloats the diff, generates merge conflicts, and breaks the reviewer's ability to see what actually changed — and "semantically perfect" is an assumption, not a guarantee, in code with no tests covering the converted paths.

A codebase's stylistic age is a fact, not an emergency. Migrations are planned work with owners and test plans, not ambient behavior of every passing edit.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No Drive-By Modernization

Write your changes in the style the surrounding code already uses. NEVER convert existing code to newer syntax, idioms, or APIs as a side effect of another task.

The core problem: idiom conversions are behavioral changes wearing a style costume (execution order, scoping, lifecycle timing all shift), and bundling them into unrelated diffs ships those changes unexamined.

- Old-but-working constructs stay: callbacks, `var`, `%` formatting, string concatenation, class components, explicit loops, older API styles
- New code you add should match its immediate surroundings first, modern preference second; a consistent file beats a half-migrated one
- Do not convert sync to async or callbacks to promises while editing a function for another reason; these change semantics, not just appearance
- Do not replace deprecated-but-functioning APIs in passing; deprecation handling is its own task with its own testing
- One construct conversion is allowed: code you are already rewriting line-by-line as the actual task may use current idioms for those exact lines
- If the old style genuinely blocks the task (e.g., you need await inside a callback chain), say so and confirm the conversion before making it; if it merely offends, mention it in a sentence and move on

**Red flags that you're about to violate this:**
- "While editing this, I'll convert it to async/await..."
- "`var` should be `const`, trivial improvement..."
- "This is the legacy way of doing it, I'll update it..."
- "Modern syntax here makes the code more maintainable..."
- "The linter would complain about this old pattern anyway..."
- "Half the file is new style already, I'll finish the job..."

---

## Why It Works

1. **It strips the costume.** The AI categorizes idiom swaps as cosmetic; naming the semantic payload (ordering, scoping, lifecycle) moves them into the "behavioral change" category its scope discipline already covers.

2. **It inverts the consistency argument.** "Half-migrated, I'll finish it" is the strongest pull; declaring that a consistent file beats a half-migrated one only until someone orders the migration cuts that off — matching surroundings is consistency.

3. **It permits exactly the defensible case.** Lines being rewritten anyway can be modern; this precision stops the rule from being dismissed as anti-improvement, while keeping untouched lines untouched.

4. **It demands confirmation for forced conversions.** Sometimes modernization really is required by the task; making it an explicit checkpoint distinguishes "required" from "preferred" in the AI's own reasoning.

## Origin

Asked to add a retry to one network call, an assistant converted the surrounding callback chain to async/await for readability. The conversion subtly changed when a connection-cleanup callback ran, from before-response-handling to after. Under load, sockets exhausted and the service tipped over during a traffic spike three weeks later. The incident timeline pinned it to a commit whose message was "add retry to fetchInventory," and the retry itself was innocent.
