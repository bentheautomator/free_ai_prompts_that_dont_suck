---
title: Surface Partial Failures in Batch Operations
slug: surface-partial-failures-in-batch-operations
category: error-handling
tags: [universal, errors, batch]
works_with: all
severity: critical
one_liner: "AI batch jobs claiming success while a third of the items quietly failed"
---

# Surface Partial Failures in Batch Operations

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents batch jobs from declaring victory while silently dropping the items that failed.

**[Copy-paste ready version](../../install/surface-partial-failures-in-batch-operations.md)** — just the instruction block, no explanation.

## The Problem

The loop looks responsible: `for record in records: try: process(record) except Exception: logger.warning(f"skipping {record.id}")`. Then the function returns normally, the job framework marks the run green, and the caller — human or machine — learns that the batch "succeeded." It did not. Two hundred of nine thousand records were skipped, their failures recorded only as warnings in a log stream nobody tails. The function's return value, exit code, and metrics all assert a completeness that is false.

This is the standard AI answer to "make the import not crash on bad rows," and the continue-on-error part is often right — one malformed record shouldn't kill the other 8,800. The missing half is the accounting. A batch operation has a richer outcome than success/failure: it has *counts*. Succeeded, failed, skipped, and which ones. AI-generated batch code almost never returns that structure, because the happy-path signature (`def import_records(records) -> None`) was set before error handling was considered, and the except-and-log clause gets bolted in without changing what the function tells its caller.

Downstream, "the job ran" becomes institutional truth. Nobody reconciles. The dropped records surface months later as missing data with no obvious origin.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

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

---

## Why It Works

1. **It splits the decision the model conflates.** "Should one bad item kill the batch?" and "should failures be surfaced?" are independent questions; the model answers no to the first and lets that answer leak into the second. Separating them keeps resilience without buying silence.

2. **It demotes logging from contract to diagnostics.** The log line is what lets the model feel the failure was "recorded." Stating that the return value is the contract removes the credit the model gives itself for a warning nobody reads.

3. **It makes partial failure machine-visible.** Exit codes and status fields are what schedulers, retries, and alerts actually consume; requiring the failure to appear there connects the rule to the systems that act on it.

4. **It frames recoverability as the test.** "Could someone retry exactly the failed items tomorrow?" is a concrete bar that log-only skipping fails and result-object accounting passes.

## Origin

A nightly job synced employee records into a benefits platform; an assistant had hardened it with per-record try/except so "one bad record can't block payroll data." Correct instinct, no accounting. When an upstream schema change made 4% of records fail parsing, the job kept exiting 0 every night for two months. The missing employees were discovered when one of them tried to use insurance that was never activated. The post-incident fix was twenty lines: a failure list, a count in the summary, exit code 1, and an alert on nonzero failures.
