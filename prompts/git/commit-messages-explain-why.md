---
title: Commit Messages Explain Why, Not What
slug: commit-messages-explain-why
category: git
tags: [universal, git]
works_with: all
severity: medium
one_liner: "Stops commit messages that just restate the diff"
---

# Commit Messages Explain Why, Not What

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents commit messages that narrate the diff instead of recording the reason the change exists.

**[Copy-paste ready version](../../install/commit-messages-explain-why.md)** — just the instruction block, no explanation.

## The Problem

"Update user.py. Changed timeout from 30 to 60. Added null check in parse_response." That's not a commit message; that's `git diff` with worse formatting. AI assistants produce these constantly because the diff is the input they summarize, and summarizing what's in front of you is easier than recording intent. The *what* is permanently stored in the commit itself; restating it adds zero information.

Six months later someone runs `git blame` on the timeout and finds "changed timeout from 30 to 60." They already knew that — it's the line they're looking at. What they needed was "payment provider's p99 latency exceeds 30s during settlement windows; see incident #4521." The why is the only part of a commit that exists nowhere else in the repository, and it's the part diff-narrating messages omit entirely.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Commit Messages Explain Why, Not What

Write commit messages that record why the change was made. NEVER write a message that merely restates the diff; the diff already stores the what, permanently and precisely.

- Subject line: imperative mood, under 72 characters, naming the change at the level of intent: `fix: prevent session expiry during long uploads`, not `update session.py`.
- Body (for anything non-trivial): explain the motivation — the bug observed, the requirement, the constraint that forced this approach. If you considered an obvious alternative and rejected it, say why in one line.
- Banned message patterns: `update <filename>`, `fix bug`, `changes`, `address feedback`, `WIP`, and any message that lists edited files or paraphrases hunks line by line.
- If you genuinely don't know why the change is being made, that's a signal to ask the user, not to write a vague message around the gap.
- Include issue or ticket references when the user has mentioned them.
- Don't pad: a one-line subject is correct for a genuinely trivial change. The rule is no missing why, not mandatory essays.

**Red flags that you're about to violate this:**

- "I'll just summarize what the diff does."
- "The change is self-explanatory, the filename is enough."
- "I don't actually know why this was needed, but 'fix bug' covers it."
- "Listing the modified functions makes the message look thorough."
- "It's a small commit, the message doesn't matter."

---

## Why It Works

1. **It reframes the task from summarization to preservation.** The AI defaults to summarizing the diff because that's the artifact in view; the rule points out that the diff is already stored, making summarization definitionally worthless and redirecting effort to the only non-redundant content.
2. **The banned-pattern list catches failures mechanically.** "Update user.py" can be rejected by string matching, no judgment required, which makes the rule enforceable even when the AI is rushing.
3. **"Ask instead of writing around the gap" closes the vagueness escape hatch** — the moment the AI can't state the why is exactly when it produces its worst messages.

## Origin

During an outage, an engineer traced a regression to a one-line config change committed eight months earlier by an AI assistant. The message read, in full, "update config." The original requester had left the company, the ticket was never linked, and the team burned two hours reverse-engineering whether the value was load-bearing before they dared revert it. It was.
