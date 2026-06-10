---
title: Fix the Typo, Not the Function
slug: fix-the-typo-not-the-function
category: scope
tags: [universal, scope, focus]
works_with: all
severity: medium
one_liner: "AI turning a one-character typo fix into a rewrite of the surrounding code"
---

# Fix the Typo, Not the Function

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from "improving" a function when it was only asked to fix a typo inside it.

**[Copy-paste ready version](../../install/fix-the-typo-not-the-function.md)** — just the instruction block, no explanation.

## The Problem

You ask for a one-character fix: `recieve` should be `receive`. The diff comes back at 40 lines. The typo is fixed, yes — and the function now uses early returns instead of nested ifs, the loop became a `.map()`, two variables have new names, and there's a fresh docstring. You wanted a diff a reviewer could approve in two seconds. You got one they have to actually read.

AI assistants do this because they evaluate the whole function while editing one token of it, and everything they'd write differently registers as an improvement worth making. More polish feels like more value delivered. But the user asked for a typo fix precisely because they wanted a trivial, zero-risk change — and the rewrite destroys exactly that property. Now the diff can't be rubber-stamped, `git blame` on every line of that function points at "fix typo," and if anything in it breaks next week, the typo commit is a suspect.

The fixed typo is worth thirty seconds. The unrequested rewrite costs a careful review, a misleading history, and a small but real chance of a regression in code that was working fine.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Fix the Typo, Not the Function

When asked to fix a typo, a string, a name, or any similarly trivial change, change ONLY that. Do not improve, restructure, or modernize the code that surrounds it.

The core problem: a trivial fix is requested because the user wants a trivial diff. Bundling improvements into it converts a zero-risk change into one that needs real review.

- The diff should contain the requested fix and nothing else. For a typo, that is typically one line
- Do not restructure control flow, convert loops to functional style, rename variables, or add docstrings to the function you are editing
- Do not fix other typos, formatting, or "obvious issues" you notice nearby
- If the typo appears in multiple places (e.g., a misspelled identifier used at five call sites), fixing all occurrences of that same typo is in scope; fixing different problems is not
- If you spot something genuinely broken nearby, finish the typo fix as requested, then mention the other issue in one sentence and offer to fix it separately

**Red flags that you're about to violate this:**
- "Since I'm editing this function anyway, I'll clean it up..."
- "This nested if could be much more readable..."
- "I'll fix the typo and also modernize this loop..."
- "The function is missing a docstring, I'll add one..."
- "These variable names are unclear, quick rename while I'm in here..."
- "It's a small function, rewriting it properly takes the same effort..."

---

## Why It Works

1. **It defines the deliverable as the diff, not the code.** The AI optimizes whatever it thinks the product is. Stating that the product is a minimal, rubber-stampable diff makes every extra line a defect instead of a bonus.

2. **It closes the "same effort" loophole.** The AI reasons that rewriting is cheap for it, ignoring that review cost is paid by humans. Naming review burden as the cost makes the tradeoff visible.

3. **It provides a legitimate outlet.** The AI's observations about nearby code aren't worthless, so the rule routes them into a one-sentence mention instead of suppressing them, which makes compliance easier than smuggling.

4. **It handles the genuine ambiguity.** Multi-site typos are the one case where "more than one line" is correct, and spelling that out removes the excuse for broader edits.

## Origin

A developer asked an assistant to fix a misspelled log message before tagging a release. The assistant fixed it and also refactored the function's error handling "for clarity," changing a fall-through case along the way. The release went out with the refactor, a previously handled error path started throwing, and the hotfix that followed took longer than the entire feature the release contained. The original request had been a five-second change.
