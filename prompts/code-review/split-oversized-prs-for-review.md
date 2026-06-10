---
title: Split Oversized PRs Into Reviewable Units
slug: split-oversized-prs-for-review
category: code-review
tags: [universal, review, prs]
works_with: all
severity: high
one_liner: "Stops 4,000-line single PRs that nobody can meaningfully review"
---

# Split Oversized PRs Into Reviewable Units

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents single pull requests so large that review degrades into scrolling and praying.

**[Copy-paste ready version](../../install/split-oversized-prs-for-review.md)** — just the instruction block, no explanation.

## The Problem

An AI assistant given a meaty task will happily produce one pull request touching 40 files across the data layer, the API, the UI, and the test suite, then present it as a single unit of work. Technically it is one feature. Practically it is unreviewable: defect-detection in review falls off a cliff as diffs grow, and a reviewer staring at 4,000 changed lines stops reading and starts skimming. Skimmed reviews approve bugs.

Assistants default to this because "one task, one PR" is the path of least resistance. Splitting requires planning a dependency order between changes, and nothing in the assistant's reward structure punishes a big diff — the human's attention span pays that cost, not the model. The assistant finished; whether anyone can verify the work is somebody else's problem.

The result is predictable: the reviewer leaves two surface-level comments on the first three files, writes "rest LGTM," and a logic error in file 31 ships. When it blows up, everyone agrees the PR was "technically reviewed."

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Split Oversized PRs Into Reviewable Units

ALWAYS structure work so each PR is independently reviewable. A PR a human cannot hold in their head is a PR that will be approved without being read.

Large diffs don't get reviewed more slowly; they get reviewed less. Your job includes making verification possible, not just making code exist.

- Before opening a PR, estimate its review surface. If it exceeds roughly 400 changed lines of hand-written code (generated files, lockfiles, and snapshots excluded), propose a split before opening it.
- Split along reviewable seams: refactor-only PR first, then behavior change; schema/migration separate from application logic; mechanical renames separate from everything.
- Each PR in a sequence must build, pass tests, and make sense on its own. "Part 1 of 3 that compiles only after part 3" is not a split, it's a big PR with extra steps.
- State the sequence in each description: what landed before it, what depends on it.
- If the human explicitly asks for one large PR, comply, but say which sections deserve the closest read.
- Never pad a small PR to "batch things up" — that is the same failure in reverse.

**Red flags that you're about to violate this:**

- "It's all one feature, so it belongs in one PR..."
- "Splitting it now would take longer than just shipping it..."
- "Most of these 3,000 lines are straightforward, the reviewer can skim..."
- "I'll mention it's a big one in the description, that covers it..."
- "The changes are too interleaved to separate at this point..."

---

## Why It Works

1. **It makes reviewability a deliverable.** The default frame is "task done when code works." Redefining the job as "code a human can verify" removes the loophole where a giant diff still counts as success.
2. **A numeric threshold forces the conversation early.** "Too big" is negotiable in the moment; "roughly 400 lines, propose a split first" triggers before the sunk-cost rationalization ("too interleaved to separate now") becomes true.
3. **It names the seams.** Assistants often agree splitting is good but claim it's impossible. Listing concrete split lines (refactor/behavior, schema/logic, rename/everything) converts "impossible" into a checklist.
4. **The standalone-buildability rule kills fake splits.** Without it, the model satisfies the letter of the rule with three PRs that only work together, which is worse than one.

## Origin

A team asked their assistant to add multi-currency support and got a single 47-file PR mixing a money-type refactor, new API fields, and a migration. The reviewer approved after a day of skimming. A rounding bug in the conversion path, sitting in plain sight on a file nobody reached, spent three weeks in production miscounting invoices. The rewrite was done as five sequential PRs; the same reviewer caught two bugs in part two within an hour.
