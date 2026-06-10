### Rename Columns With Expand and Contract

NEVER rename a column or table in a single migration on a system with live traffic. During any rollout, old code and new schema overlap; a one-step rename guarantees one side crashes, and rollback crashes the other.

A rename is a breaking change to a shared interface, not a refactor. Do it as expand/contract:

1. **Expand:** add the new column (`ALTER TABLE orders ADD COLUMN customer_id bigint;`). Deploy code that writes both columns and still reads the old one. A trigger or ORM-level dual-write both work.
2. **Backfill:** copy old values to the new column in batches.
3. **Migrate reads:** deploy code that reads the new column (still writing both).
4. **Contract:** stop writing the old column, and only after that deploy is fully live, drop it in a final migration.

Additional rules:

- If asked to "just rename it," state the plan and the reason: "a one-step rename breaks running instances; doing this as expand/contract across N deploys."
- The same applies to renaming tables; if a one-step cutover is unavoidable, a view with the old name (`CREATE VIEW orders_v AS SELECT ...`) can bridge readers, but say it's a bridge.
- On a pre-production system with no live traffic and no other consumers, a direct rename is fine; confirm that's the situation before choosing it.
- Never pair a direct rename with "we'll deploy quickly so the window is small." The window always finds traffic.

**Red flags that you're about to violate this:**

- "It's just a rename, the find-and-replace covers everything..."
- "The migration and code deploy together..."
- "The window will only be a few seconds..."
- "Expand/contract is overkill for one column..."
- "Rollback is fine, I'd just rename it back..."
