---
title: Don't Reorder Side Effects When Extracting
slug: dont-reorder-side-effects-when-extracting
category: refactoring
tags: [universal, refactoring]
works_with: all
severity: high
one_liner: "Stops extract-and-move refactors from changing the order of side effects"
---

# Don't Reorder Side Effects When Extracting

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from changing the execution order of writes, sends, and other side effects while regrouping code into cleaner functions.

**[Copy-paste ready version](../../install/dont-reorder-side-effects-when-extracting.md)** — just the instruction block, no explanation.

## The Problem

Extract-function refactors look order-neutral and aren't. To pull related statements into a helper, the assistant groups them by *theme*: all the validation here, all the persistence there, the notification at the end. But the original interleaving was often deliberate. The audit log was written *before* the external call so there'd be a record even if the call hung. The cache was invalidated *after* the DB commit, not before, to avoid serving a value that might get rolled back. The email went out only after the payment captured. Regroup by theme and these orderings quietly change, while the function's return value, the thing tests check, stays identical.

Models do this because grouping-by-concern is what "clean code" looks like in their training data, and because statement order without a data dependency reads as free to rearrange. A pure function's statements often are. Side effects are the exception, and the model doesn't reliably distinguish a reorderable computation from an unreorderable write to the outside world.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Don't Reorder Side Effects When Extracting

When refactoring, preserve the exact execution order of all side effects: database writes, network calls, queue publishes, file operations, cache updates, log lines, metric emissions, and mutations of shared state. NEVER let regrouping statements into helpers change the sequence in which the outside world sees them.

Tests check return values; almost nothing checks ordering. Reorderings ship green and fail under partial failure, concurrency, or crash, exactly when order mattered.

- Before restructuring, list the side-effecting statements in execution order. After restructuring, trace the new execution order. The two lists must match.
- Grouping by theme (all validation, then all persistence, then all notification) is allowed only if it provably doesn't move any side effect relative to another. When themed grouping would reorder effects, keep the interleaving and group something else.
- Watch the classic landmines: log-before-call vs log-after-call, cache invalidation vs DB commit order, write-then-notify vs notify-then-write, acquiring/releasing in LIFO order, and "send the receipt" relative to "charge the card."
- Moving a side effect across a conditional or loop boundary changes how many times and whether it runs. That's reordering's bigger sibling; same rule.
- Pure computations may be reordered freely if no data dependency objects. The rule is about effects, not arithmetic.
- If an ordering looks wrong or pointless, preserve it and flag it in your summary. Interleavings that survived in production are usually crash-ordering decisions wearing casual clothes.

**Red flags that you're about to violate this:**

- "I'll group all the database operations together for readability."
- "Moving this log line to the end of the function is tidier."
- "The order of these calls doesn't matter; they're independent."
- "Validation should all happen up front, so I'll hoist these checks."
- "The function returns the same result, so behavior is unchanged."

---

## Why It Works

1. **It corrects the model's definition of "behavior."** "Same return value" is the model's working test of equivalence; the rule extends equivalence to the externally observable event sequence, which is what downstream systems and crash recovery actually depend on.
2. **The two-list trace is order-checking made mechanical.** Models can't intuit ordering violations from reading their own clean output, but they can diff two explicit sequences.
3. **It targets themed grouping by name.** "All persistence together" is the specific aesthetic that causes most reorderings; calling it out as conditional rather than forbidden keeps the cleanup available when it's actually safe.
4. **The crash-ordering framing reframes pointless-looking interleavings.** Once "log before call" is understood as a partial-failure decision, the model stops reading it as sloppiness to fix.

## Origin

A checkout-flow refactor regrouped a handler so all persistence ran together at the end, which moved the order-confirmation publish ahead of the inventory decrement instead of after it. Under normal load, nothing changed. During a deploy that briefly slowed DB commits, downstream consumers received confirmations for orders whose inventory writes then failed, and the warehouse picked items that were never actually reserved. The original interleaving had been somebody's fix for exactly this.
