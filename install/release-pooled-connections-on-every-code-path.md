### Release Pooled Connections on Every Code Path

Every acquired pooled resource MUST be released on every exit path — success, exception, early return, timeout, cancellation. Use the language's scope-guaranteed construct, never a release call at the end of the happy path.

- Use the guaranteed-cleanup idiom: `try/finally` or context managers (`with pool.connection()`) in Python, `try { ... } finally { client.release() }` in Node, `defer rows.Close()` / `defer conn.Release()` immediately after acquisition in Go, try-with-resources in Java. Acquisition and guaranteed release should be adjacent lines.
- Prefer APIs that scope the resource for you: `pool.query()` over manual `connect()`/`release()` when you don't need a transaction; helper functions like `withConnection(fn)` that own the acquire/release pair so callers can't get it wrong.
- In transactions, ensure rollback-then-release on the error path; releasing a connection with an open failed transaction back to the pool poisons the next borrower with "current transaction is aborted" errors.
- Set pool guardrails as defense in depth: acquisition timeout (so exhaustion produces loud fast errors, not silent hangs), max lifetime, and idle timeout. Log or alert on pool wait time and checked-out count — a leak is visible in those metrics weeks before the outage.
- Audit any early `return`, `continue`, or thrown exception between acquire and release — each one is a leak path unless the release is scope-guaranteed.
- The same rule covers file handles, locks, semaphores, and HTTP response bodies (unclosed bodies pin connections in keep-alive pools).

**Red flags that you're about to violate this:**
- "I release it at the end of the function."
- "The error case is rare, it won't matter."
- "The pool will clean up idle connections eventually." (Checked-out isn't idle. It waits forever.)
- "Adding try/finally everywhere is noisy."
- "GC will close it when the object is collected." (Maybe. Eventually. After the outage.)
- "We restart nightly anyway."
