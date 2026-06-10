---
title: Don't Merge Lookalike Functions
slug: dont-merge-lookalike-functions
category: refactoring
tags: [universal, refactoring]
works_with: all
severity: high
one_liner: "Stops DRY merges of similar-looking code that serves different masters"
---

# Don't Merge Lookalike Functions

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from deduplicating coincidentally similar functions into one shared abstraction that couples unrelated behaviors.

**[Copy-paste ready version](../../install/dont-merge-lookalike-functions.md)** — just the instruction block, no explanation.

## The Problem

Two functions that look 90% identical trigger every deduplication instinct an AI assistant has. `validate_shipping_address` and `validate_billing_address` differ by two lines, so the assistant merges them into `validate_address(type)` with a branch inside. The diff shrinks, DRY is served, and a trap is set: those functions were similar by coincidence of their current requirements, not by shared identity. Shipping addresses are about deliverability; billing addresses are about payment-processor matching. The day one of them needs a change (shipping adds PO-box rejection), the change lands inside the shared function, behind a flag, or worse, not behind a flag, and billing validation changes too. Nobody asked it to.

Models over-merge because textual similarity is what they can see, while *reason for existence* is what actually determines whether code is duplicated. True duplication is one rule written twice. Coincidental similarity is two rules that currently rhyme. Merging the second kind doesn't remove duplication; it manufactures coupling, and the cost is paid later, by someone else, in a part of the system the original diff never mentioned. During the merge itself, the model also tends to "reconcile" the small differences between the copies, which is a behavior change in its own right.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Don't Merge Lookalike Functions

NEVER merge similar-looking functions, branches, or classes just because their text mostly matches. Merge only when they are the same *rule*, meaning they must always change together. Similar code with different reasons to change is not duplication; it's coincidence, and merging it couples things that will need to diverge.

- Before deduplicating, ask: if requirement A changes for one copy, must the other change identically, always? Only "yes" justifies a merge. "They happen to do the same thing today" is "no."
- Domain ownership is the strongest signal: code serving different business concepts (shipping vs billing, trial vs paid, import vs export) stays separate even at 95% textual overlap. Different masters, different functions.
- When you do merge true duplication, the unified function must reproduce BOTH originals exactly. Map every divergent line into the merged version and verify each original call site gets its exact old behavior. Do not "reconcile" small differences; those differences are behavior.
- A merged function that immediately needs a `type` or `mode` parameter and internal branching on it is a confession: you've stapled two functions together, not found one. Prefer keeping both, optionally extracting only the genuinely shared mechanical parts (parsing, formatting) into helpers.
- Two or three copies of something small is an acceptable state. The rule of three exists because the first "duplication" is usually coincidence; wait until the pattern proves itself.
- If you suspect real duplication but can't verify the always-changes-together property, leave the copies and note the suspicion for the user.

**Red flags that you're about to violate this:**

- "These two functions are nearly identical; this is obvious duplication."
- "One parameterized function is cleaner than two copies."
- "I'll unify these and handle the differences with a flag."
- "DRY says this shouldn't exist twice."
- "While merging, I'll also fix the slight inconsistency between them."

---

## Why It Works

1. **It replaces the textual test with the change-together test.** The model's duplication detector is string similarity; "must they always change identically?" is the question that actually distinguishes shared rules from rhyming ones, and it's answerable from context.
2. **The mode-parameter confession gives a self-check on output.** A model can't always reason about future divergence, but it can notice that its merged function needed a `type` flag and internal branches, which is the structural signature of a bad merge.
3. **It separates the two failure modes of merging.** Coupling (wrong things joined) and reconciliation (differences silently erased) get distinct rules, so a merge that passes the first test still can't smuggle behavior changes through the second.
4. **Sanctioning small duplication removes the pressure.** The model deduplicates partly because it believes copies are inherently wrong; the rule of three legitimizes the wait-and-see state that makes restraint possible.

## Origin

A cleanup merged `calculate_invoice_total` and `calculate_quote_total`, which differed only in whether a rounding adjustment applied. The merged function took an `is_quote` flag; in reconciling the two, the assistant applied the invoice rounding to both paths "for consistency." Quotes began differing from their eventual invoices by a few cents, which sales noticed only when a customer's procurement department rejected a mismatched pair, and which took an afternoon of spelunking to trace back to a deduplication.
