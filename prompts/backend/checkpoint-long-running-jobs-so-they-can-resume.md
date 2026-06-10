---
title: Checkpoint Long-Running Jobs So They Can Resume
slug: checkpoint-long-running-jobs-so-they-can-resume
category: backend
tags: [universal, backend, jobs]
works_with: all
severity: high
one_liner: "Lets multi-hour jobs survive a deploy instead of restarting from zero"
---

# Checkpoint Long-Running Jobs So They Can Resume

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents long-running jobs from losing hours of progress — or redoing already-completed side effects — every time the process restarts.

**[Copy-paste ready version](../../install/checkpoint-long-running-jobs-so-they-can-resume.md)** — just the instruction block, no explanation.

## The Problem

Tell an assistant to "backfill the embeddings for all documents" or "migrate all users to the new schema" and it writes a loop: fetch everything, iterate, process. All progress lives in the loop variable. The job is structurally incapable of surviving a restart — and restarts are not rare events. Deploys happen daily. Kubernetes evicts pods. Spot instances get reclaimed. OOM killers do not check whether you were 94% done.

When the process dies at hour six of seven, one of two bad things happens on rerun. If the work isn't idempotent, the job redoes completed items: re-sends six hours of emails, re-charges processed records, duplicates rows. If it is idempotent, the job spends six hours re-doing work that's already done before reaching the part that isn't — and if average time-to-restart is shorter than total runtime, the job *never finishes*. Teams discover this when a backfill has been "running" for two weeks because it dies at hour five of six, every time, forever.

Assistants write the straight-line loop because the prompt describes a straight line, and because at dev scale the whole job finishes in forty seconds. Durability of progress is an invisible requirement until the dataset takes longer to process than the process lives.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Checkpoint Long-Running Jobs So They Can Resume

Any job that processes a large dataset or runs longer than a few minutes MUST persist its progress and resume from the last checkpoint after a restart. Assume the process WILL be killed mid-run — by a deploy, an eviction, or an OOM — and design for the rerun, not just the run.

- Persist a durable cursor as work completes: the last processed ID, timestamp watermark, batch number, or offset, stored in a database or the job's own state table — not in process memory, not in a local file on an ephemeral disk.
- On startup, read the cursor and continue from it. Starting from zero must be an explicit operator choice, never the default.
- Process in ordered, deterministic batches (by primary key range or stable cursor) so "resume from checkpoint" has a well-defined meaning. Unordered `OFFSET` pagination shifts under you.
- Advance the checkpoint only after the batch's work is durably complete — checkpoint-then-process loses the batch on a crash between the two.
- Make each item's processing idempotent anyway (skip-if-done guard or upsert), because a crash mid-batch means the batch boundary will be replayed.
- Record per-item failures and continue; don't let item 41,007 kill a million-item run. Park failures for later review.
- Log progress (`processed 412000/1900000, cursor=812345`) so operators can distinguish "slow" from "stuck" and estimate completion.

**Red flags that you're about to violate this:**
- "The job should finish in one go, it's a single script."
- "If it fails we can just run it again from the start."
- "I'll keep a counter of where we are." (In memory. Where counters go to die.)
- "Restarts are rare, this isn't worth the complexity."
- "I'll wrap the whole thing in one big transaction." (Hours-long transactions are their own incident.)
- "We only need to run this once."

---

## Why It Works

1. **It converts restart from a disaster into a no-op.** With a durable cursor, a kill at hour six costs one batch, not six hours — which means deploys no longer have to wait for the backfill.
2. **It fixes the never-finishes failure mode.** A job whose runtime exceeds mean-time-between-restarts mathematically cannot complete without resume capability. Checkpointing makes total runtime irrelevant.
3. **It sequences checkpoint-after-work.** The naive version checkpoints first and silently loses a batch per crash; stating the ordering removes the most subtle variant of the bug.
4. **It pairs the cursor with idempotency.** The crash always lands mid-batch eventually, so the boundary is always replayed eventually. The two mechanisms cover each other's blind spot.

## Origin

A data team ran a one-off migration over 40 million records, estimated at nine hours. The platform's deploy cadence restarted services roughly every six. The job ran for eleven days, always dying between hours four and six, always restarting from record zero — and because the early records included welcome-email side effects, a subset of users received the same onboarding email up to forty times. A fifteen-line checkpoint table ended both problems the same afternoon.
