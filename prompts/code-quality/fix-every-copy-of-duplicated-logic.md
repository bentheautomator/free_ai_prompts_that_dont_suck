---
title: Fix Every Copy of Duplicated Logic
slug: fix-every-copy-of-duplicated-logic
category: code-quality
tags: [universal, duplication, edits]
works_with: all
severity: high
one_liner: "AI fixing a bug in one copy of cloned logic and leaving its twins broken"
---

# Fix Every Copy of Duplicated Logic

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from patching one instance of duplicated logic while identical broken copies live on elsewhere.

**[Copy-paste ready version](../../install/fix-every-copy-of-duplicated-logic.md)** — just the instruction block, no explanation.

## The Problem

Real codebases contain cloned logic — the same date-boundary calculation in three report modules, the same input-normalization block in two handlers, copy-pasted years ago by humans who meant to clean it up. When a bug is found in one copy, the AI fixes... that one copy. The bug report said "the weekly report is off by one day," the AI found the off-by-one in `weekly_report.py`, fixed it, and never asked the one question that mattered: *does this exact broken pattern exist anywhere else?*

The model behaves this way because it solves the ticket in front of it; the symptom defined the search, and the search ended at the first hit. The result is the worst of all states: the codebase now contains the *fixed* version and the *broken* version of the same logic side by side. The monthly report still skews. Worse, the next investigator finds the corrected copy first, concludes the logic is fine, and looks elsewhere — the half-fix actively camouflages its surviving twins. Bugs in duplicated logic must be fixed as a set or the fix itself becomes misdirection.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Fix Every Copy of Duplicated Logic

When you fix a bug, ALWAYS check whether the broken pattern exists elsewhere — and fix every copy in the same change. Codebases contain cloned logic, and a bug born in a copy-paste lives in every descendant of that paste.

A half-fixed duplicate set is worse than unfixed: the corrected copy becomes evidence that the logic is fine, hiding the broken twins from the next investigation.

**After identifying any bug, before declaring it fixed:**
- Search for siblings of the broken code: grep for the distinctive expression itself (the wrong comparison, the off-by-one boundary, the bad regex), for nearby unusual strings, and for the function/variable names involved
- Check structurally parallel locations even when text differs: if the bug is in the weekly report, read the monthly and quarterly ones; if it's in the `create` handler, read `update`; the same hand usually wrote all of them the same way
- Fix every instance you find, in this change — a list of "other places to fix later" is how twins survive
- If the copies should obviously be one function, note that consolidation is warranted and ask — but never let the prospect of a refactor delay fixing all copies *now*; matching fixes first, consolidation as a separate decision
- Report the full count in your summary: "this bug existed in 3 places; fixed all 3" — or "searched for duplicates, found none." Make the search visible either way

**Red flags that you're about to violate this:**
- "Found the bug, fixed it." (singular, no search)
- "The ticket only mentions the weekly report..."
- "The other modules are probably structured differently..." (read them, don't probably them)
- "I'll fix this instance and flag the rest..."
- "Fixing the others is scope creep..." (it's the same bug)
- Closing out a bug fix without having grepped for the broken pattern even once

---

## Why It Works

1. **It extends the unit of work from symptom to pattern.** The AI's task boundary is the reported symptom. Redefining the bug as "the pattern, wherever it occurs" makes the duplicate search part of the fix rather than an optional extra.

2. **It names the camouflage effect.** "Half-fixed is worse than unfixed" is counterintuitive enough that without stating it, the AI rates a partial fix as partial progress. Understanding that the fixed copy *misleads future debugging* prices the omission correctly.

3. **It searches by structure, not just string.** Text-grep finds literal clones; the parallel-location check (weekly→monthly, create→update) finds the clones that drifted textually but kept the bug. Both searches together cover how duplication actually looks after a few years.

4. **It makes the search auditable.** Requiring "found N copies, fixed N" or "searched, found none" in the summary means the absence of a search is visible — which is exactly the pressure that makes the search happen.

## Origin

A discount-calculation bug — tax applied before the discount instead of after — was reported on the checkout page and fixed there by an AI session in minutes. The same pasted block lived in the invoice generator and the refund calculator. For six more weeks, invoices disagreed with checkout totals and refunds disagreed with both, generating a steady drip of support tickets that all got triaged separately because, after all, checkout had been fixed. The eventual cleanup commit fixed two copies and consolidated all three; the support backlog took longer.
