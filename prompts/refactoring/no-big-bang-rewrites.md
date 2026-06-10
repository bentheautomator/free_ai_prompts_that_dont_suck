---
title: No Big-Bang Rewrites
slug: no-big-bang-rewrites
category: refactoring
tags: [universal, refactoring]
works_with: all
severity: critical
one_liner: "Stops wholesale rewrites where a sequence of small safe steps was asked for"
---

# No Big-Bang Rewrites

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from replacing a working module wholesale when it was asked to refactor it incrementally.

**[Copy-paste ready version](../../install/no-big-bang-rewrites.md)** — just the instruction block, no explanation.

## The Problem

Ask an AI assistant to "refactor this 800-line service," and there's a good chance it returns a brand-new 500-line service with different structure, different names, and a confident summary of how much cleaner it is. Somewhere in those 300 deleted lines were three timezone workarounds, a retry path for a flaky vendor API, and a guard that only matters during end-of-month billing. None of them survived, and nobody finds out until they fire.

Assistants do this because generating fresh code is what a language model is best at. Producing a coherent new file in one pass is easy; performing twelve surgical edits that each leave the system working is hard, slow, and requires actually tracking state. So the model takes the path of least resistance and calls the result a refactor.

A real refactor is a sequence of small, individually verifiable transformations: extract this function, then rename that variable, then move this block. Each step is boring. That's the point. Boring steps can be checked; a 600-line replacement diff cannot.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No Big-Bang Rewrites

NEVER refactor by rewriting a file or module from scratch. ALWAYS decompose the refactor into a sequence of small, independently verifiable transformations, and apply them one at a time.

Wholesale rewrites silently drop edge cases, workarounds, and fixes that took years to accumulate. A pile of small mechanical steps preserves them; a regeneration does not.

- Before touching code, list the planned steps (e.g. "1. extract validation into `validate_order`, 2. replace the three duplicated blocks with calls to it, 3. rename `tmp` to `pending_orders`"). Each step should be a named, recognizable transformation: extract, inline, rename, move.
- Each step must leave the code compiling and the tests passing. If a step can't, it's two steps.
- Prefer the smallest diff that achieves each step. If your diff for one step exceeds roughly 50 changed lines, stop and split it.
- If the code is genuinely beyond incremental repair, say so and ask whether the user wants a rewrite. A rewrite is a different task with different risks, and it requires explicit sign-off. Never silently upgrade "refactor" into "rewrite."
- After each step, re-read the diff and confirm no behavior changed: same inputs, same outputs, same side effects, same errors.

**Red flags that you're about to violate this:**

- "Honestly, it's easier to rewrite this file from scratch."
- "The structure is so tangled that incremental changes won't help."
- "I'll rewrite it carefully and keep all the behavior, basically."
- "Most of this code is doing the same thing anyway."
- "A clean-slate version will be much easier to review."
- "I'll just restructure everything in one pass to save time."

**Output checkpoint:** Before submitting a refactor, confirm you can name each transformation you applied. If the honest answer is "I rewrote it," start over.

---

## Why It Works

1. **It names the substitution before it happens.** The model's instinct is to regenerate, and "it's easier to rewrite this from scratch" is the exact thought that precedes the failure. Pre-naming the rationalization makes it recognizable in flight.
2. **The step list forces a plan that's checkable.** "Extract, rename, move" are transformations with known correctness properties; "rewrite carefully" is a vibe. Demanding named steps converts the task from generation to verification.
3. **The 50-line ceiling is a tripwire, not a rule of style.** It gives the model a concrete signal that it has drifted from refactoring into rewriting, which it otherwise cannot perceive from inside the act.
4. **The escape hatch keeps the rule honest.** Some code does need a rewrite. Routing that through explicit user sign-off means rewrites still happen, but never disguised as refactors.

## Origin

A team asked an assistant to refactor a shipping-cost calculator that had grown to 700 lines. The assistant produced a beautiful new version, 60% shorter, that passed the existing tests. Three weeks later, every order shipped to a freight-only postal region was quoted at standard ground rates: the rewrite had dropped an unlabeled special case that no test covered. The refund bill exceeded the value of every cleanup the team did that quarter.
