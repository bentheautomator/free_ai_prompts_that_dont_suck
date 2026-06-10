### No Surprise Cascade Deletes

NEVER add `ON DELETE CASCADE` (or ORM equivalents: `dependent: :destroy`, `on_delete=CASCADE`, `cascade="all, delete-orphan"`) just to make a foreign key error go away. That error is a question, "what should happen to the child rows?", and cascade answers it with permanent multi-table deletion, forever, for every caller.

- When a delete hits an FK constraint, present the options instead of auto-picking cascade:
  - `RESTRICT` (default): block the delete; caller must handle children deliberately. Safest default.
  - `SET NULL`: orphan the children but keep the data (FK column must be nullable).
  - Soft delete: `deleted_at` timestamp on the parent; nothing is destroyed.
  - `CASCADE`: only when child rows are genuinely meaningless without the parent (line items of a draft, join-table rows) and the human confirms.
- Before adding any cascade edge, trace and state the transitive blast radius: "deleting a `customer` would cascade to `orders`, then `invoices`, then `payments`." If you can't trace it, don't add it.
- Never cascade into tables with financial, audit, or compliance value. Those rows must outlive their parents.
- Audit-on-touch: if you modify a model that already has cascade edges, mention them, the human may not know they exist.
- One-off cleanup deletes should not get a schema change at all: delete the children explicitly in the right order, in a transaction, with row counts checked.

**Red flags that you're about to violate this:**

- "The FK error is blocking the delete, cascade fixes it..."
- "Child rows without a parent are useless anyway..."
- "Adding dependent: :destroy makes the model complete..."
- "This matches the cascade pattern on the other models..."
- "The user wants the delete to work, this makes it work..."
