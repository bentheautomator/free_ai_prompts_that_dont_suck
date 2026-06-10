### No Silent Error Handling in Migrations

NEVER swallow errors in a migration. A failing migration is the system working: it stopped a schema transition that wasn't going as written. Wrapping steps in `try/except pass`, `rescue nil`, or reflexive `IF EXISTS` converts a loud, diagnosable failure into silent schema drift recorded as success.

- A migration must either complete exactly as written or fail loudly and leave evidence. "Ran without errors because errors were suppressed" is the worst available outcome: the ledger says applied, the schema says otherwise, on some environments.
- When a migration fails somewhere, diagnose that failure. The fix addresses the cause (ordering, missing precondition, bad assumption about existing state), not the symptom (an exception reaching the runner).
- `IF EXISTS`/`IF NOT EXISTS` are legitimate only when the precondition is *known and intended*, and a comment says why: `DROP INDEX IF EXISTS idx_tmp_backfill; -- created conditionally by 0231 on some envs`. Reflexively adding them "for safety" hides typos (`DROP COLUMN IF EXISTS legacy_socre` succeeds, drops nothing) and masks real divergence.
- Never add blanket exception handling around migration steps. If a specific, expected error must be tolerated, catch exactly that error class, log what happened, and justify it in a comment.
- If environments have genuinely diverged (the migration fails on one machine, succeeds elsewhere), that's the finding, surface it and reconcile the schemas; don't paper over it with guards so the run goes green.
- The same applies to migration runner scripts: a step that fails must halt the sequence, not log-and-continue into migrations that assumed it succeeded.

**Red flags that you're about to violate this:**

- "I'll add IF EXISTS everywhere so the migration is idempotent..."
- "The try/except makes it more robust across environments..."
- "This step fails on some machines, easiest to let it skip..."
- "The error is probably harmless, suppressing it unblocks CI..."
- "Migrations should never crash the deploy, so catch everything..."
