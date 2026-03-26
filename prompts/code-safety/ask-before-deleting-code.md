---
title: Ask Before Deleting Code
slug: ask-before-deleting-code
category: code-safety
tags: [universal, foundational, essential]
works_with: all
severity: critical
one_liner: "AI silently removing code it thinks is unused"
---

# Ask Before Deleting Code

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from silently removing code it thinks is "unused" or "unnecessary."

## The Problem

You ask the AI to add a feature or fix a bug. Along the way, it notices some code it considers dead, redundant, or outdated. Without saying anything, it deletes it. You don't notice until later — when something breaks, or you realize the "dead" code was actually called dynamically, used in tests, or intentionally kept for a reason the AI couldn't see.

This happens because AI assistants optimize for "clean code" by default. They see unused imports, functions with no apparent callers, and commented-out blocks as mess to clean up. But they're working with incomplete context — they can't see runtime behavior, dynamic dispatch, or your future plans.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Ask Before Deleting Code

NEVER delete, remove, or comment out existing code without explicit approval.

**Before removing anything, you MUST:**
1. List exactly what you want to remove (file, function, lines)
2. Explain why you think it should be removed
3. Wait for explicit "yes" before proceeding

**Why:** AI assistants routinely misjudge code as "dead" or "unused" when it's actually called dynamically, used in tests, kept intentionally, or part of an unreleased feature. Silent deletion causes hard-to-diagnose regressions.

**This applies to:**
- Functions, methods, classes, or modules you think are unused
- Imports that appear unnecessary
- Commented-out code blocks
- Configuration entries or environment variables
- Test files or test cases
- "Legacy" code that looks outdated

**The only exception:** Code you just wrote in this session that hasn't been committed. You can freely modify your own work.

---

## Why It Works

1. **Forces the AI to articulate its reasoning.** When required to explain *why* something should be removed, the AI often catches its own bad assumptions. "I think this is unused" becomes "actually, I'm not sure — let me check."

2. **Shifts the burden of proof.** Without this rule, the default is "delete unless proven needed." This flips it to "keep unless proven unnecessary" — which matches how experienced developers actually work.

3. **Creates a natural checkpoint.** The pause between "I want to remove this" and "go ahead" gives you time to say "actually, that's there for a reason" — before the damage is done.

## Origin

Every experienced AI-assisted developer has a story about this. The AI "cleans up" a file while implementing a feature, removes a function it thinks is dead, and three days later something breaks in production. The function was called via reflection, or from a script, or from a different repo entirely. The AI had no way to know — but it deleted it anyway because it looked tidy.
