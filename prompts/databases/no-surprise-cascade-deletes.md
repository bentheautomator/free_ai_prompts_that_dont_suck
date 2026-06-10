---
title: No Surprise Cascade Deletes
slug: no-surprise-cascade-deletes
category: databases
tags: [universal, databases, sql]
works_with: all
severity: critical
one_liner: "Adding ON DELETE CASCADE that silently wipes child rows across tables"
---

# No Surprise Cascade Deletes

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents cascade rules, added to silence FK errors, from turning single-row deletes into multi-table purges.

**[Copy-paste ready version](../../install/no-surprise-cascade-deletes.md)** — just the instruction block, no explanation.

## The Problem

A delete fails with `violates foreign key constraint`, and the AI reads that as an obstacle rather than a message. The "fix" writes itself: change the constraint to `ON DELETE CASCADE`, and the error disappears. So does something else. Every future delete of a parent row now silently destroys its children, and the children's children, hop by hop through the schema. Delete one user to honor a GDPR request, lose their orders; the orders cascade to invoices; the invoices were your financial records. Nobody decided that. A constraint decided it, added months earlier to make one error go away.

AI assistants love cascades for the same reason they're dangerous: they make deletion code shorter and error-free. ORM equivalents (`dependent: :destroy`, `cascade="all, delete-orphan"`, `on_delete=CASCADE`) get sprinkled into model definitions as boilerplate "completeness," each one a standing decision about data destruction that no human reviewed as such. And cascades compound: each individual edge looks reasonable, while the transitive closure, what actually gets deleted when you delete a customer, is something nobody has ever looked at.

The FK error the AI silenced was the database asking a real question: what should happen to these children? "Delete them too" is sometimes the right answer. It should never be the *default* answer, and it should never be chosen by whoever was just annoyed by an error message.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

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

---

## Why It Works

1. **It reframes the FK error as a question.** The AI treats constraint violations as bugs to silence; presenting them as the database requesting a decision changes the response from "remove obstacle" to "answer question."

2. **It demands the transitive trace.** Cascade danger lives in the closure, not the edge. Forcing the AI to write out the full chain makes "deleting a customer deletes payments" visible before it's true.

3. **It offers a menu with a safe default.** RESTRICT, SET NULL, and soft delete give the AI legitimate completions for the task, so cascade stops being the only way to make the error disappear.

4. **It separates one-off cleanup from schema policy.** Most cascade additions happen in service of a single delete; routing that case to explicit ordered deletes keeps a temporary need from becoming a permanent destruction rule.

## Origin

To make an account-deletion endpoint pass its test, an assistant added cascade rules down the chain from accounts to projects to documents. Months later, support deleted a duplicate account that had been accidentally linked to the wrong organization's projects, one DELETE, 30,000 documents gone, none of them belonging to the deleted account's owner. The restore took a weekend. The cascade had been reviewed as "fixes FK error on account deletion," which was true.
