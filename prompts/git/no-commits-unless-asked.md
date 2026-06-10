---
title: No Commits Unless Asked
slug: no-commits-unless-asked
category: git
tags: [universal, git, essential]
works_with: all
severity: medium
one_liner: "Stops the AI from committing when you only asked for changes"
---

# No Commits Unless Asked

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from wrapping every edit in an unrequested commit, taking the review step away from the user.

**[Copy-paste ready version](../../install/no-commits-unless-asked.md)** — just the instruction block, no explanation.

## The Problem

"Add input validation to the signup form" is a request for code. Many AI assistants deliver the code *and* a commit — sometimes a commit and a push — because finishing the story feels like part of the job. But an uncommitted diff and a commit are different deliverables: the diff invites review, while a commit declares the work accepted and stamps it into history with an AI-authored message. The user wanted to read the change first, maybe adjust it, maybe fold it into a differently-shaped commit with their other work. That option was just taken from them.

The unrequested commit also drags the user's own staged changes along if any were sitting in the index, welding their half-finished work to the AI's change under a message they never wrote. Undoing all this is possible (`git reset HEAD~1`) but should never be necessary. Assistants do it because tutorials end with a commit, so "task complete" pattern-matches to "committed."

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No Commits Unless Asked

Do not create commits unless the user explicitly asked for a commit. "Fix the bug," "add the feature," and "refactor this" are requests for changes; the deliverable is a working tree the user can review, not a commit.

- After making changes, stop. Summarize what you changed and let the user review the diff. Committing is their call unless they delegated it in so many words.
- Words that authorize a commit: "commit," "commit this," "make a commit when done." Words that do not: "finish it," "ship it" (ask what they mean), "clean this up," task descriptions of any kind.
- Never push unless pushing was also explicitly requested; a commit authorization is not a push authorization.
- If the user has staged changes in the index when you would commit, stop regardless of instructions; an authorized commit of your work is not an authorization to commit theirs.
- For multi-step tasks where intermediate commits genuinely help (e.g. a long refactor the user asked you to commit "as you go"), that standing instruction counts as explicit; absent it, batch nothing into history.
- If you believe a commit is genuinely needed (e.g. to run a tool that requires a clean tree), say so and ask; do not commit as a workaround silently.

**Red flags that you're about to violate this:**

- "The task is done, so the natural last step is committing it."
- "A good assistant delivers a complete unit of work."
- "The user will obviously want this committed; I'm saving them a step."
- "I'll commit so the change doesn't get lost."
- "Committing makes my work look finished."

---

## Why It Works

1. **It separates two deliverables the AI conflates.** "Changes" and "committed changes" feel like the same thing at different completeness levels; the rule defines them as different products with different authorizations, so completing one no longer implies the other.
2. **The explicit vocabulary list removes interpretation.** "Did the user ask for a commit?" becomes string matching against actual words, not a judgment about what they probably wanted.
3. **The staged-changes guard protects the user's index**, which is the highest-damage variant of this failure and the one the AI is least likely to check for on its own.

## Origin

A developer asked an assistant to "tighten up the error handling in the export module" while they had unrelated staged changes queued for a carefully structured commit. The assistant made good edits, then helpfully committed — sweeping the staged work into a commit titled "improve error handling in export module." Unpicking the weld took longer than the error-handling work itself, and the developer's first instruction in every session since has been "don't commit anything."
