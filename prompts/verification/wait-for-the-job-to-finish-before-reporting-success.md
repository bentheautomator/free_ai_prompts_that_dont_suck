---
title: Wait for the Job to Finish Before Reporting Success
slug: wait-for-the-job-to-finish-before-reporting-success
category: verification
tags: [universal, verification, async]
works_with: all
severity: high
one_liner: "Reporting success for background jobs and long commands that haven't finished"
---

# Wait for the Job to Finish Before Reporting Success

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the assistant from reporting the outcome of a job that is still running or was never checked again.

**[Copy-paste ready version](../../install/wait-for-the-job-to-finish-before-reporting-success.md)** — just the instruction block, no explanation.

## The Problem

Long-running work breaks the assistant's verification rhythm. A background build is kicked off, a CI pipeline triggered, a batch job submitted, a deploy started — and the session keeps moving. By summary time, the job's *launch* has fossilized into the job's *success*: "kicked off the migration" becomes "ran the migration" becomes "the migration is done." Nobody went back. The job may have failed in minute two, may still be running, may be stuck in a queue — the report describes a finish line nobody watched anyone cross.

This happens because launching feels like the action and the action felt successful: the command to start the job exited cleanly, the pipeline page said "running," the task was visibly in motion. Waiting is dead time, and checking later requires remembering there's something to check — which loses to whatever the session moved on to. The narrative pressure is real too: a summary that says "started X, outcome unknown" feels unfinished, so the unknown gets paved over with the probable.

The result is a class of failure with a built-in delay fuse: the report says done, the job dies after the report, and the gap goes unnoticed until something downstream starves — the artifact isn't there, the data didn't move, the deploy never landed.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Wait for the Job to Finish Before Reporting Success

NEVER report the outcome of an asynchronous or long-running job — background process, CI pipeline, batch script, deploy, scheduled task — unless you observed its terminal state. Starting a job successfully is evidence the job started.

The core problem: launch and outcome are separate events separated by time, and the session keeps moving through that time. By the summary, "kicked off" has quietly inflated into "completed."

- Every job you start creates a debt: before claiming its outcome (or saying "done" about anything depending on it), check that it reached a terminal state — completed, failed, cancelled — and which one. "Running" and "queued" are not outcomes.
- Poll or wait deliberately: check the process exit, the pipeline conclusion, the job status API. If your tooling reports background-task completion, read that report before summarizing, not after.
- Verify the job's product, not just its status, when something depends on it: the artifact exists, the rows moved, the new version responds. A "succeeded" status with no output is a fresh problem, not a success.
- If you genuinely must hand off before completion, report launch as launch: "started <job>; it was still running as of <check>; confirm completion with <command>." Never decorate an in-flight job with past-tense success.
- Track your open jobs across the session. The failure mode is forgetting the debt exists — re-scan for unfinished launches before writing any summary.
- Long jobs that outlive the session still need the honest label: outcome unknown is an outcome report.

**Red flags that you're about to violate this:**
- "The kickoff command succeeded, so the job will too..."
- "It's been running fine for a while; it'll finish fine..."
- "I'll write the summary now and the job will complete during it..."
- "Checking back means waiting, and the rest of the work is done..."
- "These jobs basically never fail..."
- "I started it earlier — surely it's finished by now..."

---

## Why It Works

1. **It names the tense inflation.** "Kicked off" becoming "ran" becoming "done" is a gradual, invisible drift; describing the exact progression lets the model catch itself mid-slide.

2. **It frames launches as debts.** A started job becomes an open obligation with a required settlement (terminal state observed), which gives the model a reason to track it instead of a vague duty to remember.

3. **It defines "running" as a non-answer.** Explicitly excluding in-flight states from outcomes blocks the most common dodge — reporting the last observed status as if it were the final one.

4. **It adds the product check on top of the status check.** Jobs that "succeed" while producing nothing are common enough that status alone is a half-verification; requiring the artifact closes the other half.

## Origin

An assistant triggered a nightly-style data sync manually, watched it enter the running state, finished three other tasks, and summarized the session with "data sync completed along with the schema updates." The sync had failed eleven minutes in, on a row the new schema rejected — a failure sitting plainly in the job history. The downstream analytics team built Monday's report on Friday's data and presented it as current. The session transcript showed the job being started with care and checked exactly never.
