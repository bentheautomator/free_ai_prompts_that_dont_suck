---
title: Write PR Descriptions That Say What and Why
slug: write-pr-descriptions-with-why
category: code-review
tags: [universal, review, prs]
works_with: all
severity: medium
one_liner: "Stops PR descriptions that restate the diff and never explain the change"
---

# Write PR Descriptions That Say What and Why

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents PR descriptions that describe nothing a reviewer can't already see in the diff.

**[Copy-paste ready version](../../install/write-pr-descriptions-with-why.md)** — just the instruction block, no explanation.

## The Problem

Ask an AI assistant to open a pull request and you'll get a description like "Updated user service. Refactored validation logic. Added tests." That's not a description, it's a table of contents for the diff. The reviewer can already see that `user_service.py` changed. What they can't see is why the validation moved, what was broken before, and what they should be nervous about.

AI assistants do this because the diff is the thing they have in front of them. Summarizing files changed is mechanical; explaining intent requires committing to a claim about purpose. So they hedge by narrating the diff back at you, sometimes padded with bullet points to look thorough.

The cost lands on the reviewer. They reverse-engineer the intent from the code, guess wrong, leave comments about the wrong thing, and the review takes three rounds instead of one. Six months later, someone doing archaeology on a production incident finds a PR titled "Fix issue" with a body that says "Fixed the issue."

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Write PR Descriptions That Say What and Why

NEVER write a PR description that only restates what files changed. The diff already shows that. A description that summarizes the diff adds zero information and wastes the reviewer's first five minutes.

Every PR description must answer three questions:

- **Why does this change exist?** The bug, the requirement, the incident, the ticket. Link it if it has a link. One or two sentences of context a reviewer outside this work would need.
- **What is the approach?** Not "modified `auth.py`" but "moved token validation before the rate limiter so unauthenticated requests can't consume quota."
- **What should the reviewer scrutinize?** Risky parts, tradeoffs you made, anything you're less sure about, behavior changes that aren't obvious from the code.

Also:

- If the change has user-visible or operational impact (migrations, config, feature flags, rollout steps), say so explicitly.
- If something looks weird in the diff but is intentional, explain it in the description before the reviewer has to ask.
- Don't pad. Three honest sentences beat twelve bullet points of file names.
- Don't write "Refactored X for clarity" when you actually changed behavior. Say which behavior changed.

**Red flags that you're about to violate this:**

- "I'll just list the files I touched, that summarizes it well..."
- "The diff is self-explanatory, a short description is fine..."
- "I'll write 'various fixes and improvements' since there were several small changes..."
- "I don't have the ticket context, so I'll describe the code changes instead..."
- "Bullet points of each change will look thorough..."

---

## Why It Works

1. **It defines "description" as information not present in the diff.** The default failure is summarizing visible changes; once the rule is "the diff already shows that," restating it is recognizably zero-value and the model reaches for intent instead.
2. **The three questions are a completeness check.** "Why / approach / scrutinize" can't be satisfied by file lists, so the rationalization "listing files summarizes it well" fails the template before it ships.
3. **It treats reviewer attention as the scarce resource.** Framing padding as "wasting the reviewer's first five minutes" gives the model a reason to compress rather than inflate.
4. **It pre-empts the missing-context excuse.** "I don't have the ticket" usually means the assistant does know the why (it just did the work) and is declining to commit to it. Naming that rationalization closes the exit.

## Origin

A team let their assistant open PRs for a month, then had a production incident in code merged three weeks earlier. The PR that introduced it was titled "Update payment retry logic" with a body listing four changed files. Nobody on the incident call could determine what the retry behavior was supposed to be, because the only record of intent was the diff itself. The fix took forty minutes; reconstructing the original intent took two days and an interview with someone who had since changed teams.
