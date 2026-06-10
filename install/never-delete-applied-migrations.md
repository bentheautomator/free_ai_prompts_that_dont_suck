### Never Delete or Squash Applied Migrations

NEVER delete, rename, renumber, or regenerate a migration file that any database may have applied. Migration files are one half of a distributed system; the other half is the applied-migrations ledger in every database (prod, staging, CI caches, every developer machine). Deleting files strands every database whose ledger references them.

- "Clean up the migrations folder" does not mean delete-and-regenerate. A fresh consolidated migration is *unapplied* from every existing database's perspective and will try to re-create the entire schema.
- Resolve migration merge conflicts by ordering, not deletion: keep both sides, fix the dependency/ordering metadata (`dependencies` in Django, timestamps elsewhere). Never delete a teammate's migration to make the conflict go away.
- Don't regenerate a migration to change it; regeneration assigns a new identity, making the old entry an orphan and the new file a duplicate schema change.
- If consolidation is genuinely wanted, use the framework's squash mechanism, which records what the squash replaces (e.g. Django `squashmigrations` with `replaces`), and keep the old files until every environment, including the long-forgotten ones, has moved past them. This is a deliberate, coordinated operation; propose it, don't improvise it.
- Treat the migrations directory as append-only by default. The safe operations are: add a new migration. That's the list.
- Before any exception, enumerate the environments that have applied the files in question. If you can't enumerate them, the exception is off the table.

**Red flags that you're about to violate this:**

- "These 400 migration files are cruft, one clean migration is better..."
- "I'll resolve the merge conflict by dropping the other branch's migration..."
- "Regenerating the file is cleaner than editing my mistake..."
- "Nobody needs the old history, the schema is what matters..."
- "Fresh databases will build faster without all these files..."
