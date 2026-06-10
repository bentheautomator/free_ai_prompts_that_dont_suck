---
title: Keep Docstrings in Sync With Signatures
slug: keep-docstrings-in-sync-with-signatures
category: documentation
tags: [universal, docs]
works_with: all
severity: high
one_liner: "Docstrings describing parameters, returns, or exceptions the code no longer has"
---

# Keep Docstrings in Sync With Signatures

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents docstrings that describe parameters, return values, or exceptions that no longer match the function they sit on top of.

**[Copy-paste ready version](../../install/keep-docstrings-in-sync-with-signatures.md)** — just the instruction block, no explanation.

## The Problem

The AI adds a `timeout` parameter to `fetch_user()`, removes the `retries` parameter, and changes the return from a dict to a `User` object. The docstring still reads `:param retries: number of attempts` and `:returns: dict with user fields`. The signature and the docstring now describe two different functions, and only one of them executes. The other one gets read by every human and every other AI that touches this code next.

This happens because the docstring is structurally part of the function but semantically invisible to it. Changing the signature breaks call sites, which the AI fixes because the errors force it to. Changing the signature breaks nothing in the docstring, so the docstring stays frozen at whatever the function used to be. Models edit the lines they need to edit and leave adjacent prose untouched out of misplaced conservatism.

The exceptions section is the worst offender. A docstring claiming `raises ValueError on bad input` when the rewritten function now returns `None` silently means callers write `try/except` blocks that catch nothing and skip the `None` check that would have saved them.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Keep Docstrings in Sync With Signatures

NEVER change a function's signature, return type, or raised exceptions without updating its docstring in the same edit. A docstring that contradicts the signature beneath it is a bug you are introducing, not prose you are preserving.

The problem: docstrings don't break when the function changes, so they silently fossilize into descriptions of code that no longer exists.

Rules:
- When you add, remove, rename, or retype a parameter, fix the corresponding `:param:` / `@param` / `Args:` entry in the same edit
- When the return type or shape changes, fix the `Returns:` section. "Returns a dict" on a function returning a dataclass is a lie with a type annotation as a witness
- When you change what the function raises (or stop raising), fix the `Raises:` section. Documented exceptions drive callers' error handling directly
- When behavior changes (defaults, side effects, ordering), reread the prose summary too, not just the structured sections
- If you write a new function, the docstring must describe the function you wrote, not the one you planned before the implementation evolved
- After any signature edit, do one explicit pass: read the final docstring against the final signature, parameter by parameter

**Red flags that you're about to violate this:**
- "The docstring is mostly still accurate..."
- "I only touched the signature, not the documentation..."
- "Updating the docstring would bloat the diff..."
- "The parameter rename is obvious from context..."
- "I'll trust the existing docstring rather than rewrite it..."
- "Type hints make the docstring redundant anyway..."

---

## Why It Works

1. **It binds the doc edit to the edit that invalidates it.** The only moment the AI reliably knows the docstring is wrong is the moment it changes the signature. Deferring the fix means losing the knowledge.

2. **It targets the structured sections.** `Args:` / `Returns:` / `Raises:` map one-to-one to checkable facts about the signature, which turns "review the docstring" into a mechanical diff instead of a judgment call.

3. **It names the exception case explicitly.** Documented exceptions are load-bearing: callers build error handling from them. Calling that out makes the model treat `Raises:` as API surface, not commentary.

4. **The final read-back pass catches drift the edit missed.** Comparing finished docstring against finished signature is cheap and catches the cases where the implementation evolved mid-task.

## Origin

A payment service function was refactored to return `None` instead of raising `InsufficientFundsError`, with the caller updated to match. The docstring kept the `Raises:` clause. Three months later a different team integrated against the documented exception, wrapped the call in a `try/except`, and shipped a flow where failed charges fell through as successes. The bug was found by a customer, not a test, because the test author had also read the docstring.
