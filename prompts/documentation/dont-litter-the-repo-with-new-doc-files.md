---
title: Don't Litter the Repo With New Doc Files
slug: dont-litter-the-repo-with-new-doc-files
category: documentation
tags: [universal, docs]
works_with: all
severity: medium
one_liner: "Unrequested SUMMARY.md and NOTES.md files accumulating after every AI task"
---

# Don't Litter the Repo With New Doc Files

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from spawning unrequested `SUMMARY.md`, `IMPLEMENTATION_NOTES.md`, and `CHANGES_OVERVIEW.md` files at the end of every task.

**[Copy-paste ready version](../../install/dont-litter-the-repo-with-new-doc-files.md)** — just the instruction block, no explanation.

## The Problem

Task complete, the AI wants to show its work, so it writes `REFACTORING_SUMMARY.md` into the repo root. Next task: `MIGRATION_NOTES.md`. Then `API_CHANGES.md`, `TESTING_STRATEGY.md`, and a second, slightly different `NOTES.md` inside a subdirectory. Six weeks of AI-assisted development later, the repo root looks like a desk covered in post-its: a dozen orphan Markdown files, each describing the state of the code on one particular afternoon, none updated since, none linked from anything, all subtly contradicting each other and the README.

The model does this because writing a summary file *feels* like deliverable documentation, and because explaining its work is rewarded everywhere else. But a task summary belongs in the conversation, the commit message, or the PR description — places that are timestamped, attached to the change, and expected to go stale. A file in the repo claims to describe the present. These files describe a past nobody remembers, with the authority of the present tense.

Every one of them is future noise: a search hit that misleads, a doc a new hire trusts, a file someone eventually has to investigate before deleting.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Don't Litter the Repo With New Doc Files

NEVER create a new documentation file unless the user asked for one or an existing doc cannot reasonably hold the content. Your task summary is not a repo artifact.

The problem: unrequested summary and notes files describe one afternoon's work in the permanent present tense, then sit unmaintained, contradicting the README and each other.

Rules:
- Task explanations, change summaries, implementation notes, and "what I did" writeups go in your reply, the commit message, or the PR description, never in a new `.md` file in the repo
- If documentation is genuinely warranted by the change (new feature needs user docs), put it in the existing structure: the relevant section of the README, the existing page in `docs/`. Extend before you create
- Create a new doc file only when the user asked for one, the repo's structure clearly calls for it (e.g., `docs/` has one page per module and you added a module), or you proposed it and the user agreed
- When you do create one, it must be reachable: linked from the index, nav, or parent doc. An unlinked file is litter with a heading
- Never create `SUMMARY.md`, `NOTES.md`, `CHANGES.md`, `IMPLEMENTATION.md`, or any file whose audience is "whoever wants to know what I just did." That audience is in the chat, now
- If you've drafted useful prose with no home, offer it: "Want me to add this to docs/architecture.md or just leave it here?"

**Red flags that you're about to violate this:**
- "I'll document my changes in a new file for posterity..."
- "A summary file will help the next developer..."
- "This explanation is too long for a commit message..."
- "The repo has no docs folder, so I'll start one with my notes..."
- "I'll write NOTES.md so the context isn't lost..."
- "It's just one small file..."

---

## Why It Works

1. **It routes ephemeral content to ephemeral media.** Commit messages and PR descriptions are timestamped, change-scoped, and expected to age. The same prose in a repo file claims ongoing truth it can't deliver. Matching content lifespan to medium lifespan is the whole fix.

2. **Extend-before-create exploits existing maintenance gravity.** Content in the README gets seen and fixed; content in `IMPLEMENTATION_NOTES.md` gets seen by nobody until it misleads someone. Existing docs have readers; new orphans don't.

3. **The reachability requirement makes legitimate files survivable.** A linked doc enters the doc set's update loop; an unlinked one is invisible until it's wrong. Linking is the difference between documentation and sediment.

4. **The named-file blocklist hits the exact failure.** Models generate the same litter filenames repeatedly. Banning them by name converts a fuzzy norm into a string match the model reliably obeys.

## Origin

A quarterly repo cleanup found fourteen Markdown files in the root and stray subdirectories, all AI-generated task summaries, including three describing the same authentication refactor at different stages with mutually exclusive accounts of how sessions worked. A new contributor had already cited the oldest one in a design proposal. The cleanup deleted all fourteen, moved two paragraphs of still-true content into the README, and added one line to the project's AI instructions, which is the line above.
