---
title: Anonymize Prod Data Before It Becomes Fixtures
slug: anonymize-prod-data-in-fixtures
category: databases
tags: [universal, databases, seeds]
works_with: all
severity: critical
one_liner: "Copying real customer rows into seeds, fixtures, and test files"
---

# Anonymize Prod Data Before It Becomes Fixtures

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents real customer data from being copied into fixtures, seeds, and tests, where it lives in git forever.

**[Copy-paste ready version](../../install/anonymize-prod-data-in-fixtures.md)** — just the instruction block, no explanation.

## The Problem

A bug only reproduces with the real data, so the AI grabs the real data: queries the affected prod rows, pastes them into a test fixture, and writes the regression test. The test is excellent. The fixture now contains an actual person's name, email, address, and order history, committed to a repo that every engineer, every contractor, every laptop, and every CI log can see, indexed and copied forever. Git makes it permanent: even after someone notices and deletes the file, the data remains in history, in clones, and in whatever forks existed by then.

The AI does this because to a debugger, prod rows are just the most accurate test inputs available, and accuracy is what it's optimizing. It has no built-in concept that a row containing `jane.foo@gmail.com, 14 Elm St` is regulated material with different storage rules than `user1@example.com, 123 Test St`. The same blindness shows up in adjacent moves: dumping a prod table to a local file "to work with it," loading a prod snapshot into a shared dev database where everyone has access, or pasting query results with customer emails into a PR description or commit message.

The fix preserves what the AI actually needs, the *shape* of the data: same lengths, same weird unicode, same null patterns, with the identifying values swapped for fakes.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Anonymize Prod Data Before It Becomes Fixtures

NEVER copy real production rows into fixtures, seeds, tests, sample files, commit messages, or PR descriptions. Anything committed to git is permanent, widely replicated, and outside every access control the production database had.

- When a bug needs real-data shapes to reproduce, replicate the *shape*, not the values: same field lengths, same unicode quirks, same null patterns, same edge-case structure, with identifying values replaced:
  Real: `('Jane Foowicz', 'jane.foo@gmail.com', '+44 7700 900123')`
  Fixture: `('Tëst Üserwicz', 'user-7be2@example.com', '+44 7700 900000')`
  Preserve whatever property triggers the bug (the diacritic, the length, the format) and say which property that is.
- PII includes more than names: emails, phone numbers, addresses, IPs, government IDs, payment fragments, internal account IDs that resolve to people, and free-text fields (notes, messages) which are PII until proven otherwise.
- Use reserved fake domains and ranges: `example.com/.org`, `+1 555` numbers, RFC 5737 IPs (`192.0.2.x`).
- Don't dump prod tables to local files or shared dev databases as a working convenience. If a realistic dataset is genuinely needed for development, that's an anonymized-snapshot pipeline, an explicit project with sign-off, not a `COPY TO` in a debugging session.
- Query results pasted into conversations, tickets, or commit messages follow the same rule: mask the identifying columns.
- If you find real PII already sitting in fixtures, flag it immediately; deleting the file doesn't remove it from git history, so the human needs to decide on history rewriting and any notification duties.

**Red flags that you're about to violate this:**

- "The bug only reproduces with the actual record..."
- "It's just one row, and it's only an email address..."
- "This repo is private, so committing it is fine..."
- "I'll use the prod dump locally and delete it after..."
- "The PR description needs the real values for reviewers to verify..."

---

## Why It Works

1. **It gives the AI what it actually wanted.** The pull toward real data is about reproduction fidelity; "replicate the shape, name the triggering property" satisfies that goal fully, so compliance costs nothing the AI cares about.

2. **It corrects the storage-context blindness.** The AI evaluates data by usefulness, not by regulatory surface; stating that git equals permanent, replicated, and uncontrolled re-prices the paste before it happens.

3. **It closes the side channels.** Fixtures are only the most visible destination; naming commit messages, PR text, local dumps, and shared dev databases covers the copies that don't look like fixtures.

4. **It defines the found-PII protocol.** Without it, the AI's instinct is to quietly delete the file, which destroys the evidence while fixing nothing; flagging preserves the human decisions (history rewrite, notification) that actually matter.

## Origin

A regression test for a name-rendering bug shipped with a fixture of twelve real customer rows, copied from prod because they were the rows that broke. Eight months later, a routine repo scan ahead of an enterprise security review found them, and the cleanup involved rewriting git history across the main repo and two forks, rotating a token that appeared in an adjacent fixture, and a compliance write-up assessing notification obligations, several weeks of process to undo a thirty-second paste. The synthetic fixture that replaced it reproduced the bug identically; the trigger was a diacritic, not the customer.
