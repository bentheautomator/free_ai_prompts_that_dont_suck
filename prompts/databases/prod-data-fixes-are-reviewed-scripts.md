---
title: Prod Data Fixes Are Reviewed Scripts, Not Ad-Hoc SQL
slug: prod-data-fixes-are-reviewed-scripts
category: databases
tags: [universal, databases, sql]
works_with: all
severity: critical
one_liner: "Fixing prod data by typing SQL into a console instead of a reviewed script"
---

# Prod Data Fixes Are Reviewed Scripts, Not Ad-Hoc SQL

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents production data from being repaired with improvised console SQL instead of a reviewable, rehearsed, recorded script.

**[Copy-paste ready version](../../install/prod-data-fixes-are-reviewed-scripts.md)** — just the instruction block, no explanation.

## The Problem

A user reports their account is in a bad state, and the AI helpfully composes the fix right there in the prod console: an UPDATE here, a DELETE there, adjusting as it goes. Each statement is improvised against live data, executed on first draft, with no review, no rehearsal, and no record beyond scrollback. When statement two reveals that statement one was based on a wrong assumption, the "fix" is now part of the problem, and reconstructing what was actually run, in what order, with what bindings, depends on whether anyone saved the terminal output.

This is the workflow no team would accept for code, deploying first drafts straight to prod with no review, applied to something *less* forgiving than code: code has version control and rollback; data has neither unless you arrange them in advance. The AI falls into it because conversation is interactive and SQL consoles are interactive, so the console feels like the natural place to think. But thinking in the console means every half-formed idea executes.

The alternative costs maybe ten extra minutes: write the fix as a script, test it against a copy or staging, have eyes on it, then run it once against prod with verification built in. For a one-row fix that's overkill; for anything touching more rows than you can eyeball, it's the difference between an operation and a gamble.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Prod Data Fixes Are Reviewed Scripts, Not Ad-Hoc SQL

NEVER fix production data by composing SQL interactively in a prod console. Anything beyond reading rows gets written as a script, reviewed, rehearsed on non-prod data, and then executed once, with a record.

Improvised console SQL is a first draft running in production: no review, no rehearsal, no reliable record of what ran.

- Write the fix as a file: the diagnosis query, the change wrapped in a transaction, verification of affected counts, and an explicit COMMIT gated on the counts matching:
  `BEGIN; UPDATE subscriptions SET state='active' WHERE id IN (...); -- expect 3 rows` then verify, then COMMIT or ROLLBACK.
- Rehearse it where it can't hurt: staging, a local restore, or at minimum the same script with COMMIT replaced by ROLLBACK on prod to observe the counts.
- Get review for anything touching more rows than you can individually look at, or any DELETE. Paste the script, the rehearsal output, and the expected counts.
- Record the execution: script content, when it ran, what it reported. The ticket or incident doc is fine; scrollback is not.
- Capture before-state for the affected rows inside the script (`CREATE TABLE fix_20260610_backup AS SELECT ... WHERE <same predicate>`), so the fix is undoable.
- A genuinely single-row, single-column fix with the row inspected first may go through the console; say that's the judgment being made, and paste the statement and result afterward anyway.

**Red flags that you're about to violate this:**

- "It's faster to just fix it in the console while I'm looking at it..."
- "I'll adapt the query as I see what comes back..."
- "Writing a script for a two-statement fix is bureaucracy..."
- "I'm being careful, I don't need a rehearsal..."
- "I'll remember what I ran..."

---

## Why It Works

1. **It names the double standard.** "You wouldn't deploy unreviewed first-draft code; this is that, minus rollback" reframes console SQL from nimble to reckless using a standard the AI already enforces elsewhere.

2. **It separates thinking from executing.** The console's danger is that exploration and mutation share an input box; a script file gives the AI a place to think where drafts don't run.

3. **It builds the undo and the audit in.** Backup-by-predicate and gated COMMIT make recoverability a property of the script rather than a hope, and the pasted record means the next responder isn't archaeology-dependent.

4. **It leaves the single-row door open, labeled.** An absolute ban would be ignored under time pressure; an explicit small-fix exception with its own ritual keeps the rule credible and followed.

## Origin

During an incident, an engineer and their assistant fixed a billing state problem live in the prod console, eight statements over twenty minutes, each adjusted from the last one's output. Statement five used a predicate built on a misreading of statement three's result and flipped 1,800 unrelated subscriptions to a past-due state, which the team only fully mapped out two days later, because the only record of the session was one engineer's partial scrollback. The eventual remediation script was written, rehearsed, and reviewed, the way the original fix should have been.
