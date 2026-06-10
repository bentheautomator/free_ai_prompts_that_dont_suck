---
title: Revert Failed Fixes Before Trying the Next
slug: revert-failed-fixes-before-trying-the-next
category: debugging
tags: [universal, debugging]
works_with: all
severity: high
one_liner: "AI stacking fix attempt #4 on top of failed attempts #1 through #3"
---

# Revert Failed Fixes Before Trying the Next

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from trying fix attempt #4 while the corpses of attempts #1 through #3 are still in the working tree.

**[Copy-paste ready version](../../install/revert-failed-fixes-before-trying-the-next.md)** — just the instruction block, no explanation.

## The Problem

Watch an AI assistant work a hard bug across several attempts and check the working tree afterward. Attempt #1 added a lock. Didn't help. Attempt #2 changed the serialization format. Didn't help. Attempt #3 reordered initialization. Didn't help. Attempt #4 fixed it. The diff that gets presented as "the fix" contains all four — a lock nobody needs, a format change nobody asked for, a reorder nobody can explain, and somewhere in there, the actual fix.

It gets worse than messy diffs. The leftover attempts contaminate every subsequent experiment: attempt #4 was tested *on top of* #1 through #3, so it may only work in combination with one of them, or attempt #2 may have introduced a brand-new bug that the AI then starts chasing as if it were the original. The debugging session forks into an archaeology project about its own previous edits.

Assistants do this because reverting feels like losing progress, and because each new idea arrives with full attention on the future and none on the residue of the past. Forward is the only direction the token stream goes.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Revert Failed Fixes Before Trying the Next

ALWAYS fully revert a failed fix attempt before starting the next one. Every attempt must begin from the same clean baseline as the first.

Stacked failed attempts contaminate the experiment: the next fix gets tested against a mutated codebase, and any new symptom might be caused by your own residue rather than the original bug.

- When an attempt doesn't fix the bug, undo it completely — every file, every line, including "harmless" additions like logging you added as part of that theory
- Use version control to make this cheap: a clean starting commit or stash before debugging, `git diff` to audit what's currently changed, `git checkout`/`restore` to reset
- Before each new attempt, verify the working tree contains only (a) the pristine baseline and (b) deliberate instrumentation you're tracking on purpose
- If a failed attempt seems "worth keeping anyway," that's a separate proposal to make after the bug is fixed, not something to silently leave in the tree
- If behavior changes mid-session in a way you didn't predict, immediately ask: is this the bug, or debris from a previous attempt?
- The final fix must be re-verified on its own, applied alone to the clean baseline

**Red flags that you're about to violate this:**
- "That change didn't fix it, but I'll leave it since it's a reasonable improvement..."
- "No need to undo, the next change is in a different file..."
- "Reverting and re-editing wastes time; I'll just keep moving..."
- "The error is different now — interesting, let me chase that..." (without checking whether your own leftovers caused it)
- "I'll clean up the diff at the end..." (you won't remember what was load-bearing)
- Not knowing, at any given moment, exactly what's changed relative to baseline

---

## Why It Works

1. **It preserves a controlled baseline.** Each attempt tested against the same starting state means results are comparable and conclusive; stacked attempts make every result ambiguous.

2. **It prevents self-inflicted bug chases.** A large share of "the error changed" moments mid-session are caused by attempt residue. The mandatory tree audit catches that before hours go into debugging your own debris.

3. **It blocks the "reasonable improvement" smuggle.** Failed attempts survive because they get reclassified as improvements. Routing them to an explicit post-fix proposal keeps the judgment but removes the silent channel.

4. **It forces a solo re-verification of the winner.** A fix that only works atop three other changes is not the fix you think it is; applying it alone to baseline exposes that immediately.

## Origin

An assistant spent a long session on a deadlock, leaving each failed theory in place: a new mutex, a changed queue size, two reordered shutdown calls. The eventual "fix" passed — and shipped with all of it. In production the new mutex, never needed and never reviewed as its own change, deadlocked against an unrelated lock during deploys. The postmortem's root cause was, verbatim, "remnant of an abandoned debugging hypothesis."
