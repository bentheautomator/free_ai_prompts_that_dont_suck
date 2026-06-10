---
title: Add Columns Without Table Rewrites
slug: add-columns-without-table-rewrites
category: databases
tags: [universal, databases, migrations]
works_with: all
severity: high
one_liner: "Column defaults that force a full-table rewrite under an exclusive lock"
---

# Add Columns Without Table Rewrites

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents ADD COLUMN migrations whose defaults silently trigger a locked full-table rewrite on large tables.

**[Copy-paste ready version](../../install/add-columns-without-table-rewrites.md)** — just the instruction block, no explanation.

## The Problem

Two migrations that look almost identical can differ by three orders of magnitude in runtime. `ADD COLUMN flags integer DEFAULT 0` on modern Postgres is a metadata change, instant on any table size. `ADD COLUMN token uuid DEFAULT gen_random_uuid()` rewrites every row in the table while holding an exclusive lock, because a volatile default must be evaluated per row. The AI can't tell them apart, because syntactically there's almost nothing to tell apart; the difference lives in the engine's rules about which defaults are "cheap," and those rules vary by engine *and version* (Postgres before 11 rewrote for any default; MySQL's online DDL has its own matrix).

So the AI writes whichever default the model semantics suggest, tests it on a thousand-row dev table where everything is instant, and ships. On the 200-million-row prod table, the migration holds an ACCESS EXCLUSIVE lock for the duration of a full rewrite, blocking reads and writes both, and the deploy window becomes an outage window. The "fast" and "slow" versions had identical diffs in review.

The general principle the AI needs: an ALTER TABLE's cost is determined by whether the engine can do it as metadata-only, and that's a property to verify per engine and version, not assume from syntax.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Add Columns Without Table Rewrites

NEVER assume an ADD COLUMN is cheap. Whether an ALTER TABLE is a metadata-only change or a full-table rewrite under an exclusive lock depends on the default's volatility, the engine, and the version, and the slow version looks identical in the diff.

- Constant defaults are generally safe on modern engines: `ADD COLUMN flags integer DEFAULT 0` is metadata-only on Postgres 11+ and recent MySQL.
- Volatile defaults rewrite the table: `DEFAULT gen_random_uuid()`, `DEFAULT now()` in some contexts, any function evaluated per row. On a large table this is minutes-to-hours under an exclusive lock.
- For a volatile default on a big table, split it:
  1. `ADD COLUMN token uuid;` (no default, instant)
  2. Backfill in batches outside the deploy.
  3. `ALTER COLUMN token SET DEFAULT gen_random_uuid();` (applies to new rows only, instant)
  4. Add NOT NULL afterward if needed, via validated constraint.
- Before shipping any ALTER on a table that might be large: state the engine and version, state whether this specific operation is metadata-only on it, and state the table's approximate row count. If you can't fill in all three, ask or check; don't ship the guess.
- Dev-database speed is evidence of nothing. Every rewrite is instant on 1,000 rows.
- The same verify-don't-assume applies to other ALTERs: changing types, adding generated columns, and altering NULLability each have their own metadata-vs-rewrite rules per engine.

**Red flags that you're about to violate this:**

- "Adding a column is always fast..."
- "It ran instantly on my local database..."
- "The default makes the migration self-contained, no backfill needed..."
- "Postgres handles defaults efficiently now..."
- "I'll worry about table size if it becomes a problem..."

---

## Why It Works

1. **It surfaces the invisible variable.** The cost difference between two near-identical statements is exactly the kind of thing pattern-matching misses; naming volatility as the discriminator gives the AI something concrete to inspect.

2. **It requires three stated facts before shipping.** Engine, version, row count: forcing these into the response converts "probably fine" into either a verified claim or a visible gap the human can catch.

3. **It pre-builds the safe decomposition.** The four-step split delivers the same end state as the dangerous one-liner, so safety doesn't cost the feature anything, just an extra migration.

4. **It discredits the dev-speed evidence.** "It was instant locally" is the observation that falsely settles the question; explicitly ruling it out as evidence keeps the question open until real table size is known.

## Origin

A migration added a UUID column with a generated default to an events table, tested clean in dev and staging (both small), and shipped. Production's copy of that table held 340 million rows; the rewrite ran 50 minutes under an exclusive lock while everything that touched events queued and timed out. The four-step version went out the following week and was a non-event, in every sense.
