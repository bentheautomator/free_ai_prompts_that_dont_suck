---
title: Read the Surrounding Code, Not Just the Diff
slug: read-surrounding-code-not-just-the-diff
category: code-review
tags: [universal, review, context]
works_with: all
severity: high
one_liner: "Stops reviews that judge changed lines without reading what surrounds them"
---

# Read the Surrounding Code, Not Just the Diff

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents reviewing a PR by reading only the changed lines, missing every bug that lives in the interaction between the diff and the code around it.

**[Copy-paste ready version](../../install/read-surrounding-code-not-just-the-diff.md)** — just the instruction block, no explanation.

## The Problem

A diff shows a function's early-return being removed — three red lines, two green ones. Read in isolation, it's a clean simplification. Read with the full function on screen, it's a disaster: forty lines below, outside the diff's context window, the code assumed that early-return had already filtered out null tenants. The bug isn't in the changed lines. It's in the unchanged lines that trusted them.

Assistants default to diff-only review because the diff is what they're handed: it arrives pre-packaged, with three lines of context per hunk, and reviewing it produces fluent, plausible comments. Pulling the full file, the callers of a changed function, or the definition of a modified interface requires deliberate extra retrieval that nothing in the task structure demands. So the review covers exactly the lines the author already stared at, and skips the interactions — which is where most real review-catchable bugs live, since the author was looking at the changed lines too.

A diff-only review isn't a weaker review. It's a different, mostly decorative activity that produces the same "Reviewed" status.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Read the Surrounding Code, Not Just the Diff

NEVER review a change using only the diff hunks. Before commenting or approving, read enough surrounding code to know what the changed lines are embedded in and who depends on them.

The author already scrutinized the changed lines. Your marginal value as a reviewer is almost entirely in the interactions the diff cannot show.

Minimum retrieval before judging a hunk:

- The full function (and ideally the full file) containing each change, not the three context lines the diff ships with.
- For any changed function signature, return value, or behavior: the call sites. Grep for them; do not assume the diff includes them all.
- For removed code: what relied on the thing being removed (checks, ordering, side effects). Deletions look safest in a diff and are the most context-dependent change there is.
- For changed constants, configs, or schemas: every other reader of that value.
- If you reviewed something without its surroundings — say so in the comment: "judging from the hunk only, haven't read the callers." Scope your authority to your reading.

This is not "read the whole repo." It's a targeted rule: every changed line gets judged inside the structure that gives it meaning, and every contract change gets checked against its consumers.

**Red flags that you're about to violate this:**

- "The diff is self-explanatory, the change is clearly fine in isolation..."
- "Opening every touched file will take too long for a PR this size..."
- "The hunk has context lines, that's basically the surrounding code..."
- "It's a deletion, there's nothing to read..."
- "The function it calls is probably what its name says..."
- "I can infer the caller behavior from how it's used here..."

---

## Why It Works

1. **It relocates the reviewer's value.** Naming the fact that the author already reviewed the changed lines tells the model that diff-only effort is redundant effort — the payoff function points at the surroundings.
2. **The retrieval list is mechanical.** Full enclosing function, call sites, dependents of deletions, readers of changed values: each is a concrete fetch the model can execute, unlike "understand the context."
3. **Deletions get special-cased because they invert intuition.** The diff makes removals look trivially safe while making their dependents invisible — flagging this single asymmetry catches a disproportionate share of real misses.
4. **Scoped authority keeps honesty cheap.** When deep reading genuinely isn't possible, "judging from the hunk only" preserves the comment's usefulness without inflating what the review covered.

## Origin

A two-line diff changed a cache key from `userID` to `userID + region`. Reviewed as a hunk, it was an obvious correctness fix and got an immediate approval. Nobody grepped the other reader of that cache, an invalidation job in a different service directory, which kept deleting keys in the old format — meaning nothing was ever invalidated again. Stale permissions data served for eleven days, and the review that approved it had genuinely, carefully read both lines.
