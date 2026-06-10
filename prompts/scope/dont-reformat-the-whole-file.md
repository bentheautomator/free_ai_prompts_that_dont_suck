---
title: Don't Reformat the Whole File
slug: dont-reformat-the-whole-file
category: scope
tags: [universal, scope, focus]
works_with: all
severity: high
one_liner: "AI reformatting an entire file to change three lines of it"
---

# Don't Reformat the Whole File

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from rewrapping, requoting, and restyling hundreds of untouched lines around a small edit.

**[Copy-paste ready version](../../install/dont-reformat-the-whole-file.md)** — just the instruction block, no explanation.

## The Problem

A three-line change comes back as a 400-line diff. Quotes flipped from single to double, lines rewrapped at a different width, trailing commas added everywhere, import order shuffled, tabs become spaces. Somewhere in that blizzard are the three lines that matter, and the reviewer's job is now to find them — or, more dangerously, to skim and approve, because nobody reads 400 lines of "formatting."

This happens when the AI regenerates a whole file instead of editing it surgically, or applies its own style preferences (or the formatter it assumes the project uses) to everything it touches. The damage goes beyond the one review. Whole-file reformatting conflicts with every open branch that touches the file. It rewrites `git blame` so that every line now answers "who wrote this and why?" with a formatting commit. And a skimmed mega-diff is the perfect hiding place for an unintended behavioral change, which is how "formatting only" commits end up breaking things.

If the project wants a format migration, that's a dedicated commit produced by the project's own formatter, reviewed as exactly that — not a stowaway in a bug fix.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Don't Reformat the Whole File

Edit only the lines your change requires. NEVER reformat, rewrap, requote, or restyle lines you are not otherwise changing.

The core problem: formatting churn buries the real change, conflicts with everyone's open branches, rewrites blame history, and trains reviewers to skim, which is how behavioral changes slip through unread.

- Match the file's existing style exactly in the lines you add or edit: its quote style, indentation, line width, trailing-comma habits, and import ordering, even where they differ from your defaults or from the language's common convention
- Do not regenerate a file wholesale to make a small change inside it; edit in place
- Do not run or simulate a formatter over the file unless formatting is the task
- Do not "fix" whitespace, blank lines, alignment, or import order on lines outside your change
- After editing, sanity-check the diff: lines changed should be roughly proportional to the request. A small fix producing a file-wide diff means you reformatted, so redo it surgically
- If the file's formatting is genuinely inconsistent or broken, mention it in one sentence and offer a separate formatting-only change

**Red flags that you're about to violate this:**
- "I'll just clean up the formatting while editing..."
- "The project formatter would change this anyway..."
- "Easier to rewrite the file than patch it..."
- "Mixed quote styles, I'll normalize them..."
- "These imports aren't sorted, quick fix..."
- "Consistent style is part of code quality..."

---

## Why It Works

1. **It makes the diff a measurable artifact.** "Lines changed proportional to the request" gives the AI a self-check it can run after editing, catching wholesale regeneration that it doesn't notice it did.

2. **It mandates style mimicry over style correctness.** The AI defaults to its own formatting; explicitly requiring it to match the file, even when the file is "wrong," removes the conflict that produces churn.

3. **It names the skim-and-approve failure.** The AI assumes bigger diffs just cost time; pointing out that formatting noise is camouflage for behavioral bugs reframes churn as a safety issue, not an aesthetic one.

4. **It separates the legitimate task.** Format migrations are sometimes wanted; routing them to a dedicated, formatter-generated commit means the urge has a destination other than this diff.

## Origin

A two-line null-check fix arrived as a 700-line diff after the assistant rewrote the file in its preferred style. The reviewer, facing 700 lines on a Friday, approved it as "formatting plus the fix." The rewrite had also reordered two decorator lines whose order mattered. The resulting bug shipped, and the postmortem's first finding was that the actual fix would have been reviewable in ten seconds if the diff had contained only it.
