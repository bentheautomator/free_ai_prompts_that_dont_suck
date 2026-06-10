### Prod Data Fixes Are Reviewed Scripts, Not Ad-Hoc SQL

NEVER fix production data by composing SQL interactively in a prod console. Anything beyond reading rows gets written as a script, reviewed, rehearsed on non-prod data, and then executed once, with a record.

Improvised console SQL is a first draft running in production: no review, no rehearsal, no reliable record of what ran.

- Write the fix as a file: the diagnosis query, the change wrapped in a transaction, verification of affected counts, and an explicit COMMIT gated on the counts matching:
  `BEGIN; UPDATE subscriptions SET state='active' WHERE id IN (...); -- expect 3 rows` then verify, then COMMIT or ROLLBACK.
- Rehearse it where it can't hurt: staging, a local restore, or at minimum the same script with COMMIT replaced by ROLLBACK on prod to observe the counts.
- Get review for anything touching more rows than you can individually look at, or any DELETE. Paste the script, the rehearsal output, and the expected counts.
- Record the execution: script content, when it ran, what it reported. The ticket or incident doc is fine; scrollback is not.
- Capture before-state for the affected rows inside the script (`CREATE TABLE fix_20260610_backup AS SELECT ... WHERE <same predicate>`), so the fix is undoable.
- A genuinely single-row, single-column fix with the row inspected first may go through the console; say that's the judgment being made, and paste the statement and result afterward anyway.

**Red flags that you're about to violate this:**

- "It's faster to just fix it in the console while I'm looking at it..."
- "I'll adapt the query as I see what comes back..."
- "Writing a script for a two-statement fix is bureaucracy..."
- "I'm being careful, I don't need a rehearsal..."
- "I'll remember what I ran..."
