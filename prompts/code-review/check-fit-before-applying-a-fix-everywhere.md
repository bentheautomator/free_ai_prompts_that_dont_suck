---
title: Check Fit Before Applying a Fix Everywhere
slug: check-fit-before-applying-a-fix-everywhere
category: code-review
tags: [universal, review, scope]
works_with: all
severity: medium
one_liner: "Stops one review comment's fix from being pattern-matched across the codebase"
---

# Check Fit Before Applying a Fix Everywhere

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents taking a reviewer's point about one location and blanket-applying the same edit to every superficially similar spot without checking whether it applies.

**[Copy-paste ready version](../../install/check-fit-before-applying-a-fix-everywhere.md)** — just the instruction block, no explanation.

## The Problem

The reviewer comments on one line: "this `.unwrap()` can panic on malformed input — handle the error." Reasonable. The assistant fixes it — and then greps the PR for `.unwrap()`, finds nine more, and converts all of them to error handling. Three of those were on values just constructed two lines above, where unwrap was provably safe and the new error paths are dead code with invented error messages. One was in a test, where panicking is the assertion. The next review round is spent un-fixing fixes.

Assistants generalize this way because pattern-matching is their cheapest operation and "the reviewer dislikes X" is an easier rule to hold than "X is wrong *here because of this input source*." The comment had a reason attached to a context; the blanket application keeps the syntax and discards the reason. It feels like initiative. It's actually replacing the reviewer's judgment with a regex.

The two failure shapes: changed sites where the original reasoning doesn't hold (introducing bugs or dead code into spots the reviewer never flagged), and a ballooned diff that buries the one requested fix under nine speculative ones — forcing the reviewer to now review the generalization too.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Check Fit Before Applying a Fix Everywhere

NEVER blanket-apply a review comment's fix to other locations without verifying, per location, that the reviewer's reasoning holds there. The comment was about a line for a reason; the reason is the rule, not the syntax.

A review comment is a judgment with a context attached. Stripping the context and applying the edit by pattern-match replaces the reviewer's reasoning with find-and-replace.

- Extract the reason first. "Unwrap can panic *on malformed external input*" is the rule — not "unwrap bad."
- For each candidate site, check whether that reason applies: same input source? same failure consequence? same invariants? An unwrap on a value constructed one line up is a different situation than one on parsed user input.
- Sites where the reason holds: fix them, and tell the reviewer: "Applied the same fix to the two other spots that parse external input (`a.rs:40`, `b.rs:88`); left the unwraps on locally-constructed values as-is."
- Sites where you're unsure: ask in the thread instead of editing. "Does your concern also apply to the one in `flush()`? That input comes from our own serializer."
- If generalizing would grow the diff substantially, propose a follow-up PR rather than swelling this one mid-review.
- Never generalize beyond the PR's files into the wider codebase during review. That's a new change set with its own review.

**Red flags that you're about to violate this:**

- "The reviewer clearly doesn't like this pattern, I'll purge it everywhere..."
- "Fixing all ten at once shows thoroughness..."
- "Checking each site individually is slower than just changing them all..."
- "They'd have flagged the others too if they'd noticed them..."
- "Consistency matters more than whether each spot strictly needs it..."

---

## Why It Works

1. **"Extract the reason first" forces the comment to be parsed as an argument, not a pattern.** Once the reason is explicit, per-site checking becomes a real test the model can run instead of a vibe.
2. **The disclosure sentence keeps the reviewer in command of the generalization.** They flagged one site; they get to see — and veto — the inferred rule before it's fact on the branch.
3. **The ask-when-unsure branch is cheaper than both failure modes.** One thread question costs less than a wrong edit or a review round spent reverting initiative.
4. **The follow-up-PR rule protects review integrity.** It separates "the fix you asked for" from "the campaign I extrapolated," so each gets reviewed as what it is.

## Origin

A reviewer asked for a timeout on one HTTP call that hit a third-party API. The assistant added timeouts to all fourteen HTTP calls in the PR, picking 5 seconds everywhere. Twelve were fine. One was a call to a batch-export endpoint that legitimately takes two minutes; it began failing every night, silently, inside a try/except that a different blanket fix had added. The export gap was discovered at the end of the quarter, by the finance team.
