---
title: Abort When a Required Step Fails
slug: abort-when-a-required-step-fails
category: error-handling
tags: [universal, errors, exceptions]
works_with: all
severity: critical
one_liner: "AI logging an error and continuing into code that needed the failed step"
---

# Abort When a Required Step Fails

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents log-and-continue handlers that march a pipeline forward on the output of a step that failed.

**[Copy-paste ready version](../../install/abort-when-a-required-step-fails.md)** — just the instruction block, no explanation.

## The Problem

Step 2 of a five-step process throws, and the handler the AI wrote does this: `logger.error("Failed to validate order", exc_info=True)` — and then falls through to step 3. Step 3 charges the card. Step 3 was written assuming step 2 validated the order. The error *was* logged, which makes this look like responsible engineering, but logging is observation, not handling. The process continues with a hole where its precondition used to be.

This pattern shows up whenever an AI is asked to "handle errors" in sequential code: each statement gets its own try/catch-log, and control flow continues to the next statement regardless. The function becomes unable to stop. Every step executes no matter what happened before it — charging unvalidated orders, writing records with missing fields, sending confirmation emails for operations that failed.

The model produces this because log-and-continue is the handler shape that requires zero understanding of the data flow. Deciding to abort requires knowing that step 3 *depends on* step 2. Logging requires knowing nothing. The diff full of try/catch/log blocks looks thoroughly defended, and reviewers frequently wave it through.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Abort When a Required Step Fails

When a step fails and later code depends on its result, the operation MUST stop — return early, raise, or branch to a failure path. Logging an error is not handling it; a handler that logs and falls through to dependent code has handled nothing.

- Before writing any catch block, answer one question: can the code after this block run correctly if this step failed? If no, the block must end with `raise`, `return`, or `throw` — not fall through
- `logger.error(...)` followed by continuing into dependent code is forbidden; log AND abort, not log instead of abort
- Do not wrap each statement of a sequence in its own try/catch. A sequence with dependencies should fail as a unit: one try around the sequence, or no try at all, letting the error propagate to the caller
- "Continue on error" is valid only for genuinely independent work (e.g. optional notification after the core operation committed) — and then the code should say so: `# email is best-effort; order is already committed`
- If a function has grown a pattern of catch-log-continue at every step, that is a bug factory, not defensive coding; restructure rather than extend it
- When unsure whether downstream code depends on the failed step, assume it does and abort — an unnecessary abort is recoverable, an unjustified continue may not be

**Red flags that you're about to violate this:**
- "I'll log it so we know it happened, and keep going..."
- "The rest of the function should still run..."
- "We don't want one failure to stop the whole process..."
- "Each step gets its own try/catch for granularity..."
- "It's logged, so it's handled..."

---

## Why It Works

1. **It installs the dependency question as a gate.** "Can the next line run correctly if this failed?" is the one-sentence analysis that distinguishes valid continue-on-error from corruption; requiring it before every catch block puts the missing reasoning step back in.

2. **It severs "logged" from "handled."** The model treats the log line as discharge of responsibility. Stating that logging is observation forces the handler to also contain a control-flow decision.

3. **It legalizes best-effort work narrowly and visibly.** Independent side tasks genuinely should continue on error; requiring an in-code justification keeps that door open without letting dependent steps walk through it.

4. **It sets the default for uncertainty.** When the model can't trace the data flow, it previously defaulted to continue (less disruptive-looking); flipping the default to abort makes ignorance fail safe.

## Origin

An assistant added error handling to a user-provisioning script: every step wrapped, every failure logged, execution always continuing. When the directory-service call started timing out, the script logged the failure and proceeded to create accounts anyway — without group memberships, which the failed step was supposed to assign. Four hundred accounts were created over a week with no access restrictions applied. The logs had faithfully recorded every single failure; nobody was reading logs for a script that kept reporting successful runs.
