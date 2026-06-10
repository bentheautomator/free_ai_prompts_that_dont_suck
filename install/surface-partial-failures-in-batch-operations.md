### Surface Partial Failures in Batch Operations

A batch operation that skips failed items MUST surface those failures in its result — not only in its logs. NEVER return success, exit 0, or say "done" when items failed.

Skipping a bad item can be the right call; pretending it didn't happen never is.

- Return a result object with counts and identities: `{succeeded: 8800, failed: 200, failures: [{id, error}, ...]}` — not `None` or `true`
- The per-item catch must record *which* item and *which* error into that result, narrow-typed where possible — `except ValidationError as e: failures.append((record.id, e))`
- If any items failed, the overall outcome must say so: non-zero exit code or a distinct "completed with errors" status, so schedulers and alerting can see it without parsing logs
- Logging each skip is good but is not surfacing; logs are diagnostics, the return value is the contract
- Make the caller confront the result: the summary line ("Imported 8,800 of 9,000; 200 failed — IDs in failures list") belongs in the job output, the API response, or the CLI's stdout
- Failed items must remain recoverable: keep their IDs (or the rows themselves) somewhere a retry can find them — a skipped item that exists only as a log line is unrecoverable in practice
- Do not cap or sample the failure list silently; if you truncate the detail, state the true total count

**Red flags that you're about to violate this:**
- "I'll log skipped rows and keep the return type simple..."
- "The job completed, so it should exit zero..."
- "Failures are in the logs if anyone needs them..."
- "A few bad records shouldn't change the success status..."
- "I don't want to complicate the function signature for edge cases..."
