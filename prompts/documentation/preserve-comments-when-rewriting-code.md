---
title: Preserve Comments When Rewriting Code
slug: preserve-comments-when-rewriting-code
category: documentation
tags: [universal, docs, comments]
works_with: all
severity: high
one_liner: "AI silently dropping existing comments while editing or rewriting code"
---

# Preserve Comments When Rewriting Code

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from discarding hard-won comments as collateral damage when it rewrites the code around them.

**[Copy-paste ready version](../../install/preserve-comments-when-rewriting-code.md)** — just the instruction block, no explanation.

## The Problem

You ask the AI to refactor a function. It produces a clean new version — and the comment `// DO NOT reorder: bank API requires auth before locale, fails silently otherwise` is just gone. Not moved, not updated, not flagged. Gone. The AI regenerated the block from its understanding of the *code*, and comments aren't code, so they didn't survive the round trip.

This is among the most expensive documentation failures because comments in old code are concentrated institutional memory. Every `// yes, this looks wrong, see incident 2023-11` exists because someone paid for that knowledge — usually with an outage. The code's behavior may be perfectly preserved by the rewrite while the *warnings about the behavior* evaporate, which means the next editor steps on exactly the rake the comment existed to mark.

Assistants do this because rewriting is easier than editing: they emit a fresh block that satisfies the functional requirements, and comments — having no functional weight — don't make it into the output. The deletion is invisible in the AI's own summary ("refactored X, behavior unchanged") because behavior genuinely is unchanged.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Preserve Comments When Rewriting Code

NEVER drop an existing comment while editing or rewriting code. Every comment in the region you touch must end up in one of three states: carried over, deliberately updated, or explicitly called out as removed with a reason.

The core problem: comments encode paid-for knowledge — incidents, vendor quirks, rejected approaches. Rewriting code from your understanding of its behavior silently strips that knowledge, and nobody notices until the rake gets stepped on again.

Rules:
- Before rewriting any block, inventory its comments. After rewriting, account for each one
- If the code a comment described still exists in any form, the comment (or its updated equivalent) must be attached to the new form
- If you believe a comment is obsolete, do not silently delete it — say so in your response: "Removed comment about X; the constraint no longer applies because Y"
- Warnings, incident references, ticket links, and "do not" comments get the highest protection. When unsure whether one still applies, keep it
- Comment text you don't fully understand is a reason to preserve it, never a reason to drop it
- Moving code to a new file or function moves its comments with it

**Red flags that you're about to violate this:**
- "I'll regenerate this function from scratch, it's cleaner..."
- "The new code is self-explanatory, the old comments aren't needed..."
- "That comment refers to something I don't see in the code..."
- "I'm only responsible for the code being equivalent..."
- "The comment style was inconsistent anyway..."
- "It's a rewrite, so naturally the comments are replaced too..."

---

## Why It Works

1. **It makes deletion a visible act.** The failure thrives on silence: comments vanish without appearing in any diff summary. Requiring an explicit "removed because" turns an invisible loss into a reviewable decision.

2. **It inverts the uncertainty rule.** The model's instinct is "I don't understand this comment, so it's probably stale." Stating that incomprehension means *preserve* blocks the exact reasoning that deletes the most valuable warnings.

3. **It reframes rewriting as editing-with-inventory.** "Regenerate from understanding" is where comments die. An inventory step (list before, account after) forces the round trip to include non-code content.

4. **It ranks warnings highest.** Not all comments are equal; explicitly prioritizing "do not" and incident comments protects the ones whose loss costs outages rather than minutes.

## Origin

A scheduler had a one-line sleep with the comment `// 250ms: peer drops connections opened <250ms apart, confirmed with vendor`. An assistant refactored the surrounding retry logic, preserved the sleep but dropped the comment. Months later a different engineer saw an unexplained magic sleep, removed it as cruft, and shipped. The resulting connection storms took two days to trace because the explanation had been deleted in a "no behavior change" refactor that, technically, changed no behavior.
