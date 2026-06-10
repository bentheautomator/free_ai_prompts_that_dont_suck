---
title: SQL NULL Needs IS, Not Equals
slug: sql-null-needs-is-not-equals
category: language-pitfalls
tags: [universal, sql]
works_with: all
severity: high
one_liner: "Stops = NULL, <> filters, and NOT IN from silently dropping NULL rows"
---

# SQL NULL Needs IS, Not Equals

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents three-valued logic from quietly deleting rows from your results: `= NULL` matches nothing, `<> 'x'` excludes NULLs, and one NULL poisons an entire `NOT IN`.

**[Copy-paste ready version](../../install/sql-null-needs-is-not-equals.md)** — just the instruction block, no explanation.

## The Problem

In SQL, NULL is not a value — it's the absence of one, and comparing anything to it yields neither true nor false but UNKNOWN. `WHERE deleted_at = NULL` returns zero rows, always, even when half the table has NULL there. The reverse trap is sneakier: `WHERE status <> 'archived'` looks like "everything except archived" but excludes rows where status is NULL too, because `NULL <> 'archived'` is UNKNOWN and UNKNOWN rows are filtered out. The nastiest member of the family is `NOT IN`: if the subquery returns even one NULL, `x NOT IN (...)` is UNKNOWN for *every* x, and the whole query returns nothing — a correct-looking anti-join that silently produces an empty set.

Aggregates play by their own NULL rules: `COUNT(col)` skips NULLs while `COUNT(*)` doesn't, and `AVG` averages only the non-NULL rows, so two "obviously equivalent" queries disagree.

Assistants write `= NULL` and naked `<>` filters because they port equality semantics from application languages, where `x == null` is a perfectly good check. Two-valued logic is the prior; SQL's third value isn't in the muscle memory, and the broken queries *run successfully*, which deprives everyone of an error to notice.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### SQL NULL Needs IS, Not Equals

NEVER compare against NULL with `=` or `<>` in SQL — any comparison with NULL is UNKNOWN, and UNKNOWN rows are excluded by WHERE. Use `IS NULL` / `IS NOT NULL`.

- Wrong: `WHERE deleted_at = NULL` — matches zero rows unconditionally. Right: `WHERE deleted_at IS NULL`.
- Inequality filters exclude NULL rows: `WHERE status <> 'archived'` drops rows with NULL status. If NULLs should be included, say so: `WHERE status <> 'archived' OR status IS NULL`, or use `IS DISTINCT FROM 'archived'` where the dialect supports it.
- NEVER use `NOT IN` with a subquery whose column can be NULL — one NULL makes the entire predicate UNKNOWN and returns zero rows. Use `NOT EXISTS` (NULL-safe and usually better-planned) or filter NULLs in the subquery explicitly.
- NULL-safe equality where you genuinely mean "same, treating NULL as a value": standard `IS NOT DISTINCT FROM`, MySQL `<=>`. Don't emulate it with `COALESCE(col, 'sentinel')` unless the sentinel provably can't collide.
- Remember the aggregate asymmetry: `COUNT(*)` counts rows; `COUNT(col)` counts non-NULL values; `AVG(col)` divides by the non-NULL count. Pick deliberately.
- `NULL || 'text'` and arithmetic with NULL yield NULL — string-building and computed columns propagate absence; wrap with `COALESCE` when output must be non-NULL.
- In ORMs and query builders, check what `.where(field: nil)` style filters actually emit — most translate correctly, but raw-fragment escapes (`where("status <> ?")`) reintroduce the trap verbatim.

**Red flags that you're about to violate this:**

- "`= NULL` is the SQL spelling of `== null`."
- "`<> 'archived'` means everything that isn't archived." (NULL isn't 'not archived'; it's unknown.)
- "`NOT IN (subquery)` is the natural way to write this exclusion."
- "The query runs without errors, so the logic is right."
- "COUNT is COUNT; the column argument is cosmetic."

---

## Why It Works

1. **It introduces the third truth value explicitly.** The bugs all reduce to a two-valued-logic prior; once UNKNOWN-rows-get-filtered is stated, each symptom (= NULL, <>, NOT IN) follows from one principle instead of being three memorized exceptions.
2. **It hard-bans the NOT IN shape.** This one can't be patched with awareness — the safe alternative (`NOT EXISTS`) must be the reflex, so the rule mandates substitution rather than caution.
3. **It anticipates "the query ran".** Absence of an error is the model's main success signal; flagging that these queries succeed while wrong removes the false reassurance.
4. **It covers the ORM trapdoor.** Raw SQL fragments inside query builders are where the rule silently stops applying; naming them keeps the guard up at the boundary.

## Origin

A retention job selected churned accounts with `WHERE plan <> 'enterprise'` to send win-back emails. Accounts mid-migration had NULL plans and were excluded from everything — including the suppression query that was supposed to stop emails to accounts with open billing disputes, which used `dispute_id NOT IN (SELECT ...)` over a column containing NULLs. The suppression list evaluated to empty, the job emailed every disputed account, and legal got involved before engineering did.
