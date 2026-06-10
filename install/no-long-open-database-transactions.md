### No Long-Open Database Transactions

NEVER hold a database transaction open across slow or unbounded operations: network calls, file I/O, sleeps, queue publishes, or waiting for human input. A transaction holds locks and pins resources for its entire lifetime; its duration is the duration of the damage.

- Structure code as: gather everything needed (including all external calls) first, then open the transaction, do only database statements, commit. Seconds, not minutes.
- Concretely banned inside a transaction: HTTP/API calls, `sleep()`, sending email, reading user input, large in-memory processing of fetched rows, iterating a slow generator.
- In interactive sessions: do not `BEGIN`, run a statement, and then stop to ask the user a question. If verification needs human eyes, either present the plan before opening the transaction, or use a fast scripted check (row count comparison) inside it.
- If business logic seems to need external calls "inside" the transaction, restructure: write an intent row, commit, perform the call, then record the result in a second short transaction (the outbox pattern). Two short transactions beat one long one.
- Watch for framework-created long transactions: a request-scoped session that stays open while the handler calls three services has this bug without any visible BEGIN.
- Treat `idle in transaction` connections as defects. If your script can be interrupted between BEGIN and COMMIT (debugger, prompt, retry loop), it can strand one.

**Red flags that you're about to violate this:**

- "I'll wrap the whole function in a transaction to be safe..."
- "The API call usually responds quickly..."
- "I'll leave the transaction open so the user can inspect before commit..."
- "Holding locks a bit longer is the price of correctness..."
- "The session manages transactions, I don't need to think about it..."
