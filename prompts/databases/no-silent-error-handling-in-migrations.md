---
title: No Silent Error Handling in Migrations
slug: no-silent-error-handling-in-migrations
category: databases
tags: [universal, databases, migrations]
works_with: all
severity: medium
one_liner: "try/except pass and IF EXISTS sprinkled over migrations to hide failures"
---

# No Silent Error Handling in Migrations

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents migrations that swallow their own failures and report success over a schema that's now anyone's guess.

**[Copy-paste ready version](../../install/no-silent-error-handling-in-migrations.md)** — just the instruction block, no explanation.

## The Problem

A migration fails somewhere, in CI, on a teammate's machine, on a re-run after a partial failure, and the AI "hardens" it: wraps each step in `try: ... except: pass`, sprinkles `IF EXISTS`/`IF NOT EXISTS` on every statement, adds a `rescue nil` here and there. The migration now succeeds everywhere, by the simple expedient of no longer noticing when it doesn't. A typo'd column name in `DROP COLUMN IF EXISTS legacy_socre` succeeds while dropping nothing. The `except: pass` around the index creation eats a real failure (duplicate values, lock timeout), records the migration as applied, and leaves the index missing on exactly one environment, where queries will be mysteriously slow for the next year.

This is the AI's general error-handling reflex, errors are friction, wrapping them makes the program robust, applied to the one context where it's most wrong. A migration's entire job is to transition a schema from known state A to known state B. A migration that absorbs failures delivers state "B, mostly, probably," while the ledger records a clean B. Every environment that ran the swallowing version is now subtly different from every other, and the migration system, whose whole purpose is making schemas converge, has been converted into a generator of divergence.

Idempotency is a real virtue and `IF EXISTS` has legitimate uses, in migrations *designed* to be re-runnable, where the guard encodes a known, intended precondition. The failure is using guards as duct tape over failures nobody has diagnosed.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No Silent Error Handling in Migrations

NEVER swallow errors in a migration. A failing migration is the system working: it stopped a schema transition that wasn't going as written. Wrapping steps in `try/except pass`, `rescue nil`, or reflexive `IF EXISTS` converts a loud, diagnosable failure into silent schema drift recorded as success.

- A migration must either complete exactly as written or fail loudly and leave evidence. "Ran without errors because errors were suppressed" is the worst available outcome: the ledger says applied, the schema says otherwise, on some environments.
- When a migration fails somewhere, diagnose that failure. The fix addresses the cause (ordering, missing precondition, bad assumption about existing state), not the symptom (an exception reaching the runner).
- `IF EXISTS`/`IF NOT EXISTS` are legitimate only when the precondition is *known and intended*, and a comment says why: `DROP INDEX IF EXISTS idx_tmp_backfill; -- created conditionally by 0231 on some envs`. Reflexively adding them "for safety" hides typos (`DROP COLUMN IF EXISTS legacy_socre` succeeds, drops nothing) and masks real divergence.
- Never add blanket exception handling around migration steps. If a specific, expected error must be tolerated, catch exactly that error class, log what happened, and justify it in a comment.
- If environments have genuinely diverged (the migration fails on one machine, succeeds elsewhere), that's the finding, surface it and reconcile the schemas; don't paper over it with guards so the run goes green.
- The same applies to migration runner scripts: a step that fails must halt the sequence, not log-and-continue into migrations that assumed it succeeded.

**Red flags that you're about to violate this:**

- "I'll add IF EXISTS everywhere so the migration is idempotent..."
- "The try/except makes it more robust across environments..."
- "This step fails on some machines, easiest to let it skip..."
- "The error is probably harmless, suppressing it unblocks CI..."
- "Migrations should never crash the deploy, so catch everything..."

---

## Why It Works

1. **It redefines the failing migration as the success case.** The AI's reflex treats exceptions as defects in the migration; framing the failure as a stopped bad transition makes suppression the defect instead.

2. **It names the worst outcome precisely.** "Ledger says applied, schema disagrees, per-environment" is the concrete drift mechanism that "more robust" hides; once stated, the robustness framing collapses.

3. **It draws the idempotency line.** A blanket ban on `IF EXISTS` would be wrong and ignored; requiring known-precondition-plus-comment keeps the legitimate use while making duct-tape use visibly non-compliant.

4. **It catches the typo class specifically.** `IF EXISTS` turning misspelled identifiers into silent no-ops is unintuitive until named, and it's the variant that bites even careful authors.

## Origin

A migration kept failing in CI on an index that already existed there (a previous run had half-applied), so the assistant wrapped every statement in try/except and CI went green. The suppressed block also contained a unique constraint, which silently failed to apply in production, where, unlike CI, duplicate rows existed. The application spent four months assuming a uniqueness guarantee the database wasn't enforcing, and the eventual dedup-and-constrain project was a week of work that a one-time diagnosis of the CI failure would have avoided.
