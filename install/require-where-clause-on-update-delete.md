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
