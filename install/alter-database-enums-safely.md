### Alter Database Enums Safely

NEVER treat a database enum like an editable constant list. Enum values have rows sitting on them; adding has transaction quirks, and removing is a full data migration.

**Adding a value:**

- Postgres: `ALTER TYPE ... ADD VALUE` can't run in a transaction block before v12. Confirm the version; if needed, mark the migration non-transactional (`disable_ddl_transaction!`, `atomic = False`).
- Deploy the database value *before* the code that writes it. New code writing 'refunded' against an enum that lacks it is an immediate production error.

**Removing or renaming a value:**

- First check for rows using it: `SELECT count(*) FROM orders WHERE status = 'refunded';` Nonzero means you migrate that data first, deliberately (map to another value, or don't remove).
- Postgres has no DROP VALUE. The real procedure is: create the new type, `ALTER TABLE ... ALTER COLUMN ... TYPE new_type USING status::text::new_type`, drop the old type. This locks the table; treat it like any heavy ALTER on a big table.
- Often the right call is to not remove it: stop writing the value, keep it valid for historical rows, and note it as deprecated.

**Always:**

- Change both sides or neither: database enum and application enum (model enum, union type, validation list) must ship in compatible order; say which deploys first and why.
- Consider whether a lookup table or a CHECK-constrained text column fits better when values change often; suggest it when asked to modify the same enum repeatedly.

**Red flags that you're about to violate this:**

- "Adding an enum value is a one-line migration..."
- "I'll remove the unused status value while I'm in here..."
- "The app enum is updated, the database will accept it..."
- "No rows probably use that old value..."
- "Renaming the value is just cosmetic..."
