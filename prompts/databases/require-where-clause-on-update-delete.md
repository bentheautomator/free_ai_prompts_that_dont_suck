---
title: Require a WHERE Clause on UPDATE and DELETE
slug: require-where-clause-on-update-delete
category: databases
tags: [universal, databases, sql]
works_with: all
severity: critical
one_liner: "Running UPDATE or DELETE that silently hits every row in the table"
---

# Require a WHERE Clause on UPDATE and DELETE

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents unscoped UPDATE/DELETE statements from rewriting or erasing an entire table.

**[Copy-paste ready version](../../install/require-where-clause-on-update-delete.md)** — just the instruction block, no explanation.

## The Problem

"Deactivate that test user" becomes `UPDATE users SET active = false;` because the AI built the statement incrementally, meant to add the WHERE clause, and the statement was already syntactically complete without it. SQL is the only popular language where forgetting half the statement still executes successfully, and the success message, `UPDATE 184220`, arrives after the damage is done. The same shape kills with DELETE: a missing WHERE turns "remove the stale session" into an empty table.

There's a subtler variant the AI produces even more often: a WHERE clause that's present but wrong. `WHERE name LIKE '%test%'` matches the customer named "Testa." `WHERE created_at < '2026-01-01'` was supposed to be `>`. A join condition typo turns a scoped DELETE into a near-full one. The clause exists, so it pattern-matches as safe, and nobody checks what it actually selects.

Both variants have the same antidote: prove the scope before executing. Run the SELECT, look at the count, compare it to what you expected, and only then run the write with the identical predicate.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Require a WHERE Clause on UPDATE and DELETE

NEVER execute an UPDATE or DELETE without a WHERE clause, and NEVER execute one without first verifying what the WHERE clause matches.

A missing or wrong predicate is invisible until after execution; SQL happily reports success on the statement that just rewrote every row.

- Before any UPDATE or DELETE, run the same predicate as a SELECT first:
  `SELECT count(*), min(id), max(id) FROM users WHERE email = 'bob@test.example';`
- State the expected row count before running the SELECT, then compare. "Expected 1, got 1" proceed; "expected 1, got 31,407" stop and report.
- If the intent genuinely is every row, write the predicate anyway (`WHERE true`) and say explicitly: "this intentionally affects all N rows," and get confirmation outside of local/test databases.
- Be suspicious of broad predicates: `LIKE '%...%'`, date comparisons, `!=` conditions, and predicates on nullable columns all routinely match far more than intended.
- Wrap risky DML in an explicit transaction so the row count can be inspected before COMMIT:
  `BEGIN; DELETE FROM sessions WHERE user_id = 42; -- check count, then COMMIT or ROLLBACK`
- This applies equally to DML generated through ORMs: `User.update_all(...)` and `queryset.update(...)` with no filter are the same bug in nicer clothes.

**Red flags that you're about to violate this:**

- "It's just a quick UPDATE..."
- "The WHERE clause is obviously right, no need to SELECT first..."
- "I'll add the condition after I check the syntax works..."
- "This table only has the rows we want to change anyway..."
- "Running the SELECT first doubles the work..."

---

## Why It Works

1. **It converts scope from belief to measurement.** The failure isn't ignorance of WHERE clauses; it's unverified confidence in one. SELECT-first makes the blast radius a number you read instead of a guess you hold.

2. **It requires a prediction before the measurement.** Stating the expected count first is what makes the check real. Without the prediction, any count looks plausible after the fact.

3. **It covers the ORM disguise.** `update_all` with no scope doesn't look like SQL, so SQL rules don't fire. Naming the ORM forms closes the costume loophole.

4. **It keeps a legitimate path for full-table writes.** Rules with no escape hatch get ignored when the task genuinely needs all rows; the explicit `WHERE true` plus announcement keeps the rule intact for that case.

## Origin

During a support escalation, an engineer asked their assistant to clear one corrupted user preference row. The generated DELETE had a join condition referencing the wrong alias, matched 96% of the preferences table, and executed cleanly in under a second. Restoring from the previous night's backup lost a day of user settings changes. A SELECT with the same predicate would have shown six digits where one was expected.
