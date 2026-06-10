---
title: Fix the First Error in the Cascade
slug: fix-the-first-error-in-the-cascade
category: debugging
tags: [universal, debugging, errors]
works_with: all
severity: high
one_liner: "AI chasing the loudest or last error when the first one caused the rest"
---

# Fix the First Error in the Cascade

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from attacking error #47 in a cascade where error #1 caused the other 46.

**[Copy-paste ready version](../../install/fix-the-first-error-in-the-cascade.md)** — just the instruction block, no explanation.

## The Problem

A build fails with 200 errors and the AI picks one to fix — usually the last one (it's at the bottom of the output, closest in context), or the scariest-looking one, or the one whose file it has open. It patches "cannot find name 'UserRecord'" in twelve files, individually, with imports and local type aliases. The actual problem was error #1: a syntax error in `types.ts` that made the whole module fail to parse, taking every downstream name with it. Fix that one character and the other 199 errors evaporate.

Cascades are everywhere: the compiler error storm after one broken file, the test suite where 80 failures share one broken fixture, the log where ten thousand exceptions trace back to one failed startup step, the migration that failed and left every subsequent query erroring. In every case the errors are not 200 problems — they're one problem and 199 echoes. Order is causality: earlier failures poison the state that later operations depend on, so the cascade always reads forward in time from the real cause.

The AI gets this wrong because it has no instinct for output chronology — the most recent or most prominent error is the most salient, and salience beats sequence. Fixing echoes individually also generates lots of plausible-looking diffs, which feels like progress while making the codebase strictly worse.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Fix the First Error in the Cascade

When facing many errors, ALWAYS find and fix the chronologically first one before touching any other. Mass failures are usually one cause and many echoes, and causality reads forward in time.

The last error is the most visible and the least informative; the first error poisoned the state everything after it depended on.

- Scroll to the top: in compiler output, test runs, and logs, locate the *earliest* error by position or timestamp before reading any other in detail
- Fix only that one, then re-run; expect a large fraction of the remaining errors to disappear, and repeat with the new first error
- Recognize echo signatures and refuse to fix them individually: dozens of "cannot find name/module X" after one file failed to compile; many tests failing in the same fixture or setup hook; thousands of identical exceptions after one startup failure
- Never patch echoes at their own sites (adding imports for names that should resolve, re-declaring types, guarding against state a previous failure left broken) — that hardcodes the breakage
- In logs, sort by timestamp and find the first deviation from normal, not the most frequent or most severe message
- If fixing the first error doesn't shrink the count substantially, you have more than one real problem — repeat the procedure, still front-to-back

**Red flags that you're about to violate this:**
- "Let me start with this error at the bottom of the output..."
- "There are 200 errors; I'll work through them file by file..."
- "This 'cannot find name' error needs an import added..." (in twelve places)
- "The most common error message is probably the main issue..."
- Fixing any error without knowing whether an earlier one precedes it
- A diff touching many files to resolve failures that share one timestamp origin

---

## Why It Works

1. **It replaces salience with sequence.** The AI selects errors by prominence; the instruction supplies the correct selection function — earliest first — and the causal reason (earlier failures poison later state) that makes it stick.

2. **It sets the evaporation expectation.** Knowing that one fix should erase a large fraction of the errors changes the plan from "resolve 200 items" to "find the head of the chain," and provides a built-in check: if the count didn't drop, the diagnosis was wrong.

3. **It names echo signatures concretely.** "Cannot find name X, 40 times" and "all failures share a setup hook" are recognizable patterns; cataloging them lets the AI classify echoes instead of treating each as an original problem.

4. **It bans hardcoding the breakage.** Patching echoes at their own sites (extra imports, redeclared types) makes the codebase depend on the broken state; explicitly prohibiting that prevents the worst version of the failure.

## Origin

Handed a build with 175 TypeScript errors after a merge, an assistant worked from the bottom up, adding type assertions and local interface copies across fourteen files — 300 lines of "fixes" over an hour. The first error in the output, never read, was an unclosed brace in a shared types file from a bad merge-conflict resolution. One character. A developer fixed it, the build dropped to zero errors, and the fourteen files of scaffolding had to be individually reverted because by then they conflicted with the real types.
