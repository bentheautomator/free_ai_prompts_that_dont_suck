### Never Check Then Act

NEVER write code that checks a condition and then acts on it as two separate steps when concurrent callers could interleave between them. The check is stale the instant it returns. Replace the check-then-act pair with a single atomic operation and handle its failure.

- Don't check existence then create: `if not exists: insert` → use a unique constraint plus insert-and-catch-conflict, or an upsert (`INSERT ... ON CONFLICT`, `putIfAbsent`, `setdefault`).
- Don't check a file then open it: `if (!fs.existsSync(p)) fs.writeFileSync(p)` → open with exclusive-create flags (`'wx'`, `O_CREAT|O_EXCL`) and handle `EEXIST`.
- Don't check a balance/quota/inventory then deduct: read-check-write → a conditional atomic write: `UPDATE account SET balance = balance - :amt WHERE id = :id AND balance >= :amt`, then check rows affected.
- Don't check "is this slot free" then claim it (usernames, seats, locks, job leases). Claim it atomically and treat rejection as the normal path, not an error.
- When no atomic primitive exists, hold a lock around both the check and the act — the same lock for every code path that touches that state.
- Treat the conflict outcome as expected control flow: catch it, report it cleanly, retry where appropriate. "It would have already failed the check" is not a reason to skip handling it.

**Red flags that you're about to violate this:**
- "I already checked that it doesn't exist two lines up."
- "This endpoint won't get concurrent calls for the same user."
- "The window between check and act is tiny."
- "I'll validate in the app layer; the database doesn't need a constraint."
- "Adding conflict handling complicates the happy path."
