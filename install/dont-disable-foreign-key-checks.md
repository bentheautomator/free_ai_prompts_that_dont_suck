### Don't Disable Foreign Key Checks to Force a Change Through

NEVER disable foreign key or constraint checking to make a failing operation succeed. The violation is the database telling you the operation creates inconsistent data; silencing the check keeps the corruption and discards the warning.

- Banned as fixes for a constraint error: `SET FOREIGN_KEY_CHECKS=0`, `SET session_replication_role = replica`, `DISABLE TRIGGER ALL`, dropping a constraint and "re-adding it later," `NOCHECK CONSTRAINT`.
- Fix the operation instead:
  - Insert/import in dependency order: parents before children.
  - Delete in reverse dependency order: children before parents, in one transaction.
  - For data that legitimately lacks a parent, decide explicitly: create the parent, null the reference, or skip the row, and report counts of each.
- If checks must be off for a bulk load (rare, maintenance-context only):
  1. Get explicit human sign-off first.
  2. Re-validate afterward; in MySQL re-enabling checks validates nothing, so verify orphans manually:
     `SELECT c.id FROM child c LEFT JOIN parent p ON c.parent_id = p.id WHERE p.id IS NULL;`
  3. Zero orphans or the load is not done.
- In Postgres, if a constraint genuinely must be relaxed temporarily, prefer `ALTER TABLE ... ADD CONSTRAINT ... NOT VALID` then `VALIDATE CONSTRAINT`, the path that ends with the database confirming consistency.
- Never commit code or migrations that toggle constraint checks as a routine step.

**Red flags that you're about to violate this:**

- "The FK check is blocking the import, I'll turn it off temporarily..."
- "I'll re-enable the checks right after, so nothing's really off..."
- "The data is probably consistent, the constraint is just strict..."
- "Ordering the inserts correctly is too complicated..."
- "Other migration scripts online do it this way..."
