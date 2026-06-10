---
title: Route Failed Jobs to a Dead-Letter Queue
slug: route-failed-jobs-to-a-dead-letter-queue
category: backend
tags: [universal, backend, jobs]
works_with: all
severity: critical
one_liner: "Keeps failed background jobs from vanishing silently or retrying forever"
---

# Route Failed Jobs to a Dead-Letter Queue

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents background jobs from disappearing without a trace or retrying infinitely when they fail.

**[Copy-paste ready version](../../install/route-failed-jobs-to-a-dead-letter-queue.md)** — just the instruction block, no explanation.

## The Problem

When an AI assistant writes a background job, it writes the success path and maybe a `catch` block that logs the error. That's where the story ends. The job framework either drops the failed job (gone forever) or requeues it (forever, if the failure is deterministic). Both outcomes are catastrophic and both are the default behavior of "process the message, log errors" code.

The two failure shapes are mirror images. Silent drop: a payout job fails on a malformed record, the error goes to a log nobody reads, and a customer doesn't get paid — you find out from a support ticket three weeks later. Poison pill: a job fails deterministically, gets requeued, fails again, and now one bad message is consuming a worker, hammering a dependency, and clogging the queue, while the retry counter climbs into the millions.

Assistants do this because in dev, jobs don't fail. There's no malformed data, no third-party API returning a 422, no schema drift between producer and consumer. The catch-and-log pattern looks responsible — it even mentions the word "error" — but it has no answer to the only question that matters: where does the job go when it can't succeed?

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Route Failed Jobs to a Dead-Letter Queue

Every background job MUST have an explicit terminal failure destination: after a bounded number of retries, the job and its full payload land in a dead-letter queue (or failed-jobs table) where it can be inspected and replayed. A failed job that only produces a log line is a lost job.

- Configure max retry attempts on every queue and job type. Unlimited retries turn one poison message into a permanent outage; zero retries turn one network blip into lost work.
- After max retries, move the job to a DLQ with its original payload, the final error, attempt count, and timestamps. Never discard the payload — it is the only thing that makes replay possible.
- Distinguish failure types: retry on transient errors (timeouts, 5xx, deadlocks), dead-letter immediately on permanent ones (validation errors, 4xx, deserialization failures). Retrying a 422 forty times produces forty identical failures, slower.
- Alert on DLQ depth greater than zero. A dead-letter queue nobody watches is a landfill, not a safety net.
- Provide a replay path: a documented command or admin action that re-enqueues DLQ entries after the underlying bug is fixed.
- Never write a consumer whose error handling is only `log(err)` and move on — that acknowledges and destroys the message in most frameworks.

**Red flags that you're about to violate this:**
- "I'll log the error so we can investigate."
- "The job will just be retried by the queue automatically."
- "Failures here are basically impossible, the data is validated upstream."
- "We can add dead-letter handling later once this is working."
- "If it fails, the next scheduled run will pick it up."
- "Catching the exception keeps the worker from crashing, that's enough."

---

## Why It Works

1. **It defines failure as a routing problem, not a logging problem.** The assistant's default instinct is to *record* the failure; the rule forces it to decide where the work *goes*, which is the actual requirement.
2. **It bounds both failure shapes at once.** Max-retries kills the infinite poison-pill loop; the DLQ kills the silent drop. Each half alone leaves one catastrophe open.
3. **It preserves replayability.** Keeping the full payload converts an incident from "data loss" into "delayed processing," which is a different severity class entirely.
4. **It separates transient from permanent errors.** This stops the assistant from writing one retry policy for all exceptions, which is always wrong in one direction or the other.

## Origin

A billing system's invoice-generation worker caught all exceptions and logged them to keep the worker alive. A currency-formatting bug made invoices fail for one country; the jobs were acked, logged, and gone. Twenty-three days of invoices for that region simply never existed, discovered only when finance reconciled the quarter. The replay took an afternoon — reconstructing which jobs to replay took two weeks.
