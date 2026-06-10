---
title: Write TODOs With Context and Ownership
slug: write-todos-with-context-and-ownership
category: documentation
tags: [universal, docs, comments]
works_with: all
severity: medium
one_liner: "Bare 'TODO: fix this' comments with no owner, reason, or definition of done"
---

# Write TODOs With Context and Ownership

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents context-free `TODO: fix this later` comments that no one can act on, prioritize, or safely delete.

**[Copy-paste ready version](../../install/write-todos-with-context-and-ownership.md)** — just the instruction block, no explanation.

## The Problem

`// TODO: handle this properly`. Handle what properly? What happens today when it isn't handled? Is this a landmine or a nice-to-have? Written by whom, blocked on what? Two years from now this comment will still be here, and the only thing anyone will know about it is that someone, once, felt vaguely bad about this line.

AI assistants are prolific TODO generators because a TODO is the cheapest way to acknowledge a shortcut. Mid-task, the model notices an unhandled edge case, doesn't want to expand scope, and drops `// TODO: add error handling` as a moral offset. The comment costs five tokens and discharges the guilt. But the model has context a human TODO-writer would include automatically — what the gap is, what triggers it, what the fix looks like — and it throws all of that away in favor of the shortest possible confession.

A TODO without context isn't a task. It's an anxiety, serialized.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Write TODOs With Context and Ownership

NEVER leave a TODO that doesn't say what's wrong, what the consequence is, and what done looks like. A TODO is a task handed to a stranger; write it so the stranger can act.

The problem: bare TODOs ("fix this", "handle properly", "temporary") preserve the guilt but discard the context, leaving comments nobody can prioritize or resolve.

Rules:
- Every TODO states three things: the gap ("no retry on 429 responses"), the consequence ("bulk imports fail under rate limiting"), and the fix direction ("add backoff like in `sync_client.py`")
- Include a trail: an issue reference if the project tracks them, otherwise enough specifics that someone can file one
- Never write "temporary," "for now," or "later" without saying what event ends the temporary period
- If the gap is dangerous rather than cosmetic, say so in the TODO; "TODO" and "FIXME: data loss possible" should not look identical
- Before adding a TODO, consider whether the fix is under five minutes; if so, do it instead of documenting that you didn't
- When the user should know about the gap, also say it in your summary; a TODO buried in a diff is not disclosure
- Match the repo's convention if one exists (e.g., `TODO(username):`, linked ticket formats)

**Red flags that you're about to violate this:**
- "I'll just flag it with a quick TODO..."
- "The details are obvious from the surrounding code..."
- "Someone will figure out what I meant..."
- "TODO: improve this — that covers it..."
- "I don't want to clutter the comment with explanation..."
- "It's temporary anyway..."

---

## Why It Works

1. **It converts confession into specification.** Gap, consequence, fix direction is the minimum a task needs to be schedulable. Without those, a TODO can only ever be re-discovered, never resolved.

2. **It exploits peak context.** The model writing the TODO is the entity that best understands the gap, for the only time anyone will. The rule spends that context before it evaporates.

3. **The five-minute test deflates TODO-as-avoidance.** Many AI TODOs take longer to write well than to fix. Forcing the comparison eliminates the ones that exist purely to close the task faster.

4. **Severity labeling makes triage possible.** A codebase where every deferred landmine and every cosmetic wish share the format "TODO" trains readers to ignore all of them.

## Origin

A codebase audit before a migration turned up over three hundred TODOs, the majority machine-written, of the form "TODO: handle edge cases." Nobody could say which were safe to ignore, so the team spent two sprints investigating each one. Roughly a dozen marked real correctness gaps, including one unvalidated currency conversion. The other ~290 cost two sprints to establish they meant nothing.
