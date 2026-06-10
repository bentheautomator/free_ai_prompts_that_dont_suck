---
title: Escalate When Every Batch Item Fails
slug: escalate-when-every-batch-item-fails
category: error-handling
tags: [universal, errors, batch]
works_with: all
severity: critical
one_liner: "AI skip-and-continue loops grinding through 100% failure as if it were 1%"
---

# Escalate When Every Batch Item Fails

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents per-item error handling from treating a total systemic failure like a sprinkling of bad records.

**[Copy-paste ready version](../../install/escalate-when-every-batch-item-fails.md)** — just the instruction block, no explanation.

## The Problem

Per-item try/except in a batch loop is built for one threat model: occasional bad records in mostly good data. But the handler can't tell that scenario apart from a completely different one — the database credential expired, the API contract changed, the disk filled up — where *every single item* fails for the same reason. The loop doesn't care. It dutifully catches all 250,000 exceptions, logs 250,000 warnings, takes four hours to fail at everything, and exits as if it had merely encountered some rough data.

The distinction matters because the correct responses are opposite. A 0.5% failure rate is per-item business: skip, record, move on. A 100% failure rate — or 40%, or whatever crosses plausibility for the dataset — is systemic: nothing is wrong with the items, something is wrong with the *world*, and continuing is pure waste that delays the alarm by hours. Worse than waste, sometimes: a loop that "processes" every item through a failing dependency may be emitting side effects (acknowledging messages, marking rows as attempted, consuming rate limits) at full speed against a broken backend.

AI assistants never generate the failure-rate check, because the per-item catch *looks* complete. The loop handles errors; what else is there? The missing concept is that failure pattern is itself a signal the loop should be reading.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Escalate When Every Batch Item Fails

A batch loop that tolerates per-item failures MUST also detect systemic failure and abort. One hundred percent failure is not a data-quality issue — it means the system is broken, and the loop should stop and say so immediately.

- Track failures during the run, not just after: keep a failure count and check it against a threshold as the loop proceeds
- Abort early on consecutive failures from a cold start: if the first N items (e.g. 10–25) all fail, stop — the probability that your first 25 records are all individually bad is negligible compared to the probability that the credential, schema, or endpoint is broken
- Abort on failure *rate* mid-run: pick a threshold defensible for the dataset (e.g. >20% after a meaningful sample) and stop when crossed, raising an error that states the rate and a sample of the underlying exceptions
- When failures share one exception type and message, say so in the abort error — "all 25 failures: AuthenticationError" hands the operator the diagnosis
- Stopping early preserves options: items not yet attempted can be retried cleanly after the fix; items churned through a broken dependency may have half-executed side effects
- Distinguish error classes where possible: infrastructure errors (connection, auth, timeout) should trip the abort threshold faster than data errors (validation), because they're never the item's fault
- The threshold values are judgment calls — make them named constants with a comment, so they're visible and adjustable, not buried magic

**Red flags that you're about to violate this:**
- "The per-item handler already covers failures..."
- "Skip and continue — that's what batch resilience means..."
- "Counting failures mid-run is overengineering..."
- "Even if many fail, processing the rest is still progress..."
- "We'll see the failure totals in the summary at the end..."

---

## Why It Works

1. **It introduces failure pattern as data.** The model's loop reads each exception in isolation; the rule makes the *sequence* of failures — consecutive count, rate, homogeneity — an input the loop must act on.

2. **The cold-start check exploits a probability asymmetry the model can verify.** "First 25 all bad" being data is astronomically unlikely; framing it that way makes the early abort feel like inference, not impatience.

3. **It prices the cost of continuing.** "Progress on the rest" is the rationalization; pointing out that churning through a broken dependency burns hours, rate limits, and possibly side effects converts continuing from neutral to harmful.

4. **It separates whose fault the failure is.** Infrastructure errors are never the item's fault — giving that class a hair trigger encodes the systemic/data distinction directly in the handler.

## Origin

A document-ingestion job processed about 300,000 files nightly, with AI-written per-file error handling. When a storage credential was rotated without updating the job, every single file failed with the same `403`. The loop logged each one and kept going — for five and a half hours — before exiting "complete" with 300,000 warnings. The downstream search index, fed by the job, served stale data all the next day. An abort-after-ten-consecutive-failures check would have raised a clear `AuthenticationError` ninety seconds in, while the on-call engineer who rotated the credential was still at their desk.
