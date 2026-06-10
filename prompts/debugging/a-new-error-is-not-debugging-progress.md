---
title: A New Error Is Not Debugging Progress
slug: a-new-error-is-not-debugging-progress
category: debugging
tags: [universal, debugging, errors]
works_with: all
severity: high
one_liner: "AI treating a changed error message as a step toward done"
---

# A New Error Is Not Debugging Progress

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from treating "the error message changed" as evidence the fix is working.

**[Copy-paste ready version](../../install/a-new-error-is-not-debugging-progress.md)** — just the instruction block, no explanation.

## The Problem

"Good news — we're past the original error!" is one of the most reliably wrong sentences an AI assistant produces. The `TypeError` became a `KeyError`. The 500 became a 422. The crash on line 80 became a crash on line 14. The assistant narrates each transformation as forward motion and keeps editing, when in reality there are three possibilities and only one of them is good: the fix worked and revealed a pre-existing second bug; the fix merely *moved* the same bug; or — the common case — the fix *introduced* a new bug while leaving the original intact underneath.

The AI defaults to the optimistic reading because a changed output is the only feedback it got, and interpreting feedback as progress keeps the generation loop moving. Stopping to classify the new error — is this the same root cause wearing a new face? did my edit cause this? — feels like backtracking.

Sessions governed by this fallacy have a signature shape: a chain of six "fixes," each one converting the error into a different error, ending in a codebase that fails in a way nobody can relate to the original report anymore.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### A New Error Is Not Debugging Progress

NEVER treat a changed error message as progress. A different error after your edit is a new fact requiring classification, not a milestone to celebrate past.

There are three possibilities every time the error changes, and you must determine which one you're in before making another edit.

- Read the new error with the same full attention you owed the first one: complete message, complete trace, not just "it's different now"
- Classify it explicitly: (1) original bug actually fixed, distinct pre-existing bug now exposed; (2) same root cause surfacing at a different point; (3) new bug introduced by my edit, original possibly still present
- To rule out case 3, examine your own diff first — your most recent edit is the prime suspect for any brand-new failure
- To rule out case 2, check whether the new failure involves the same data, value, or code path as the original
- Case 1 may be claimed only with evidence the original failure mode is gone, not merely hidden behind the new one
- Never say "we're getting further" or "past the original error" based solely on the message changing; depth into execution is not the metric — the bug being gone is

**Red flags that you're about to violate this:**
- "Great, the original error is gone — now there's just this other issue..."
- "We're making progress, it fails later in the process now..."
- "This new error is unrelated, I'll handle it and move on..."
- "One down. Next error..." (without verifying anything went down)
- "It's a different exception type, so the first bug must be fixed..."
- Editing in response to the new error before reading its full trace

---

## Why It Works

1. **It replaces a feeling with a classification.** "Progress" is a vibe; the three-case taxonomy is a decision with evidence requirements. The AI can't skip the analysis while appearing compliant, because the classification must be stated.

2. **It points suspicion at the right place first.** Brand-new errors after an edit are most often caused by the edit. Making "examine your own diff" the first move catches case 3 before it spawns a chase.

3. **It severs "fails later" from "closer to working."** Failing deeper in execution can mean the guard that used to stop bad data early was removed. Explicitly rejecting depth-as-progress kills the most persuasive version of the fallacy.

4. **It makes victory claims falsifiable.** Requiring evidence that the *original* failure mode is gone — not just unobserved — prevents declaring case 1 by default.

## Origin

A session that started with one `NullPointerException` in an invoice formatter ran for two hours and eleven "fixes," with the assistant cheerfully announcing progress as the error mutated through a `ClassCastException`, a serialization failure, and finally a silent wrong total. The diff at the end touched nine files. When a developer reverted everything and looked at the original trace, the actual bug was a one-character typo in a field name — and error number two in the chain, it turned out, had been introduced by fix number one.
