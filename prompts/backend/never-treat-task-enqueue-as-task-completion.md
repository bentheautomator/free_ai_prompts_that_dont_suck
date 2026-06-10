---
title: Never Treat Task Enqueue as Task Completion
slug: never-treat-task-enqueue-as-task-completion
category: backend
tags: [universal, backend, jobs]
works_with: all
severity: high
one_liner: "Stops services reporting success for async work that has not happened yet"
---

# Never Treat Task Enqueue as Task Completion

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents code that enqueues async work from telling callers — and the database — that the work is done.

**[Copy-paste ready version](../../install/never-treat-task-enqueue-as-task-completion.md)** — just the instruction block, no explanation.

## The Problem

You ask the assistant to move slow work out of the request path. It obliges: the handler now calls `queue.enqueue(send_invoice, order_id)`, sets `invoice_sent = true`, and returns `200 {"status": "invoice sent"}`. Spot the lie. Nothing has been sent. A message has been *accepted for future consideration* by a broker. The handler has converted "we will try" into "we did," and persisted the claim.

The gap surfaces the first time the async work doesn't happen: the worker crashes, the job lands in a dead-letter queue, the email provider rejects the address. Now the system contains a permanent contradiction — the database says sent, the user says nothing arrived, and support has no thread to pull because every record insists the work succeeded. Multiply across exports ("your report is ready" for a report that errored), provisioning ("account created" for an account the worker never built), and downstream consumers that trusted the `*_completed` flag and acted on it. Reconciliation after the fact is archaeology.

Assistants conflate enqueue with completion because in dev the worker is always running, always fast, and never fails — so the lie is always true by the time anyone checks. The distinction only matters when something between enqueue and execution breaks, which is precisely the production-only event the async split was supposed to survive.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Treat Task Enqueue as Task Completion

NEVER report or record async work as done at the moment you enqueue it. Enqueue means "accepted," not "completed" — only the worker that finishes the job may write the completion state.

- Model the lifecycle explicitly: `pending` → `processing` → `completed` / `failed`, with the enqueueing code writing `pending` and only the worker writing terminal states. A boolean `done` flag has no room for the truth.
- Return honest responses: `202 Accepted` with a task/status reference, `"status": "queued"`, not `"sent"` / `"created"` / `"done"`. If the caller needs to know the outcome, give them a way to learn it (status endpoint, webhook, polling token) instead of a premature verdict.
- Update the record from the worker on both success and failure, including a failure reason. A job that dead-letters must leave a visible `failed` state behind — pair this with your dead-letter handling.
- Enqueue durably relative to your transaction: if you write `pending` and enqueue separately, a crash between the two strands the record. Use the transactional-outbox pattern or enqueue-after-commit with a reconciliation sweep for stuck `pending` rows.
- Sweep for zombies: anything `processing` or `pending` beyond a sane age is an alarm, not a curiosity — it means a worker died mid-job or a message was lost.
- Never let downstream logic trigger off the optimistic flag ("invoice_sent → start dunning timer"); trigger off the worker-written completion event.

**Red flags that you're about to violate this:**
- "Enqueue basically never fails, and workers always run."
- "I'll mark it done here so we don't need a second update."
- "The user wants to see 'sent', not 'queued'."
- "We can assume the background job succeeds."
- "A status column is overkill, a boolean is fine."
- "If the job fails it'll retry, so it's as good as done."

---

## Why It Works

1. **It restores the truth gap as a modeled state.** Between enqueue and completion there is a real interval where the outcome is unknown; `pending`/`processing` makes that interval visible to every reader instead of papering over it with a hopeful boolean.
2. **It assigns write authority to the only component that knows.** The worker is the sole witness to completion; restricting terminal writes to it makes "completed" mean something again.
3. **It makes failures findable.** When the DLQ fills up, worker-written `failed` states plus a zombie sweep convert "which of last month's records are lies?" into a `WHERE status = 'failed'` query.
4. **It closes the crash window with the outbox.** Naming enqueue-vs-commit atomicity prevents the adjacent bug — records that say `pending` forever because the enqueue itself was lost.

## Origin

A B2B platform marked data exports `completed` at enqueue time and emailed customers a download link in the same breath. A schema change broke the export worker for six days; jobs dead-lettered silently while every export record — and every email — claimed success. Customers clicked links to empty files, support escalated, and the team had no query that could distinguish real exports from optimistic ones; they re-ran three weeks of exports to be safe. The fix was a status column and moving one `UPDATE` into the worker.
