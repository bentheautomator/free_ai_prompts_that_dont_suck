---
title: One Logical Change Per Commit
slug: one-logical-change-per-commit
category: git
tags: [universal, git]
works_with: all
severity: medium
one_liner: "Stops grab-bag commits that weld unrelated changes together"
---

# One Logical Change Per Commit

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from packing a bug fix, a refactor, a formatting pass, and a dependency bump into one unrevertable commit.

**[Copy-paste ready version](../../install/one-logical-change-per-commit.md)** — just the instruction block, no explanation.

## The Problem

A long AI session produces real work: a bug fix, an opportunistic refactor it did along the way, a formatting cleanup its editor applied, and a config tweak that made the tests run. Then it commits all of it as one unit titled "fix payment retry bug." Every tool that operates on history just got worse: `git revert` now can't undo the fix without undoing the refactor, `git bisect` lands on a commit where four things changed, and `git blame` attributes a formatting sweep's 400 lines to "fix payment retry bug."

Assistants do this because committing is, to them, a session-ending flush rather than a curation step — everything in the tree goes in the bag, the bag gets a label describing the most prominent item. The work of splitting (staging file by file, or hunk by hunk with `git add -p` equivalents) feels like overhead because its benefits accrue to future readers the assistant never meets.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### One Logical Change Per Commit

Each commit contains exactly one logical change. NEVER bundle unrelated work — a fix plus a refactor plus formatting plus config — into a single commit because they happen to share a working tree.

The test: can you describe the commit honestly in one sentence without using "and also"? If not, split it.

- Before committing, sort the modified files (and where needed, hunks within a file) into logical groups. Stage and commit each group separately with its own message: the fix, then the refactor, then the formatting pass.
- Mechanical changes (formatting, renames, generated-file regeneration) always get their own commit, clearly labeled, so reviewers and `git blame` can skip them.
- If you fixed a bug and refactored around it, the refactor that *enables* the fix may share the commit; the refactor you did because you were in the neighborhood may not.
- Order matters: commit prerequisite changes first so each commit builds and passes tests on its own when practical.
- Don't overcorrect into confetti: ten one-line commits for one coherent change is the same disease mirrored. One logical change can be large.
- If files contain interleaved changes from different logical groups, use `git add -p` style hunk staging (non-interactively if needed) rather than giving up and committing the blend.

**Red flags that you're about to violate this:**

- "Everything in the tree is from this session, so one commit covers it."
- "Splitting this up means writing four commit messages."
- "The formatting changes are riding along, but they're harmless."
- "I'll mention the refactor in the commit body, that's basically splitting."
- "The user just wants it committed; granularity is a nicety."

---

## Why It Works

1. **The "and also" test is a self-administered classifier** — the AI can apply it to a drafted commit message in one beat, and a failed test produces an obvious split point (split at the "and also").
2. **It reframes committing from flush to curation.** Treating commit time as a sorting step rather than a save step is the single conceptual change from which the right behavior follows.
3. **Naming who benefits (revert, bisect, blame) makes the cost concrete** — assistants discount future readers by default; pointing at specific tools that break gives the abstraction teeth.

## Origin

A revert told this story best: a production incident traced to a commit named "fix date handling in reports," which also contained a dependency bump, a renamed module, and an 800-line autoformat. Reverting the date fix meant reverting all four; cherry-picking the fix apart took ninety tense minutes during the incident. The date fix itself was six lines.
