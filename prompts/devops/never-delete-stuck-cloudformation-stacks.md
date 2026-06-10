---
title: Never Delete a Stuck CloudFormation Stack to Fix It
slug: never-delete-stuck-cloudformation-stacks
category: devops
tags: [universal, devops]
works_with: all
severity: critical
one_liner: "Deleting a failed stack, and every resource in it, to clear the error state"
---

# Never Delete a Stuck CloudFormation Stack to Fix It

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from resolving a stack stuck in a failure state by deleting the stack — which deletes the infrastructure too.

**[Copy-paste ready version](../../install/never-delete-stuck-cloudformation-stacks.md)** — just the instruction block, no explanation.

## The Problem

CloudFormation's failure states read like errors that want clearing: `UPDATE_ROLLBACK_FAILED`, `ROLLBACK_COMPLETE`, `DELETE_FAILED`. An AI troubleshooting a stack in one of these states quickly discovers that most operations are refused — can't update, can't retry — and that one operation is always available: `aws cloudformation delete-stack`. So it reaches for the fresh start: delete the stack, redeploy the template, clean slate. Except a stack is not a record *about* infrastructure; it is the ownership boundary *of* infrastructure. Deleting a stuck production stack deletes the load balancers, queues, tables, and roles inside it. The "error state" was holding a fence around live resources, and the fix tore down the fence with everything attached.

The states have real, surgical exits the AI rarely reaches for. `UPDATE_ROLLBACK_FAILED` has `continue-update-rollback`, with `--resources-to-skip` for the specific resource blocking the rollback. `DELETE_FAILED` lets you retry with `--retain-resources` so stubborn resources are released from the stack rather than bulldozed. Only `ROLLBACK_COMPLETE` on a *failed initial creation* genuinely requires deletion — and that's the one case where the stack never successfully created anything worth keeping, which is exactly why it's safe. The AI generalizes from that one safe case to all the others.

There's also a quieter sibling: resolving drift or import errors by deleting and recreating the stack "to resync," with identical consequences.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Delete a Stuck CloudFormation Stack to Fix It

NEVER run `delete-stack` on a stack in a failure state as a troubleshooting step. The stack *is* the infrastructure: deleting it deletes every resource it owns. Failure states are locked, not broken, and each has a specific exit.

- First, find out what actually failed: `aws cloudformation describe-stack-events --stack-name X` and read the first `*_FAILED` event from the bottom of the failed operation — that's the root cause; everything after is cascade.
- `UPDATE_ROLLBACK_FAILED`: use `aws cloudformation continue-update-rollback`, adding `--resources-to-skip` for the specific resource that can't roll back (after fixing or understanding it). This returns the stack to operational without touching healthy resources.
- `DELETE_FAILED` (when deletion *was* intended): retry with `--retain-resources <logical-ids>` for the blockers, so they're orphaned for manual handling instead of force-bulldozed; report what got retained.
- `ROLLBACK_COMPLETE` after a *failed first creation* is the one state where delete-and-recreate is correct — nothing real was ever successfully created. Verify it's an initial create (stack has no prior successful state) before treating it that way.
- Check `DeletionPolicy` and termination protection before believing any deletion is contained; absence of `DeletionPolicy: Retain` on stateful resources means delete means delete.
- Never delete a stack to "resync" drift, clear an import error, or because the console won't let you update. If you believe deletion is genuinely necessary on a stack that has ever been healthy, list every resource in it (`describe-stack-resources`) and get explicit human confirmation against that list.

**Red flags that you're about to violate this:**

- "The stack is wedged, delete and redeploy is the clean-slate fix..."
- "delete-stack is the only operation it will accept, so that must be the path..."
- "The template is in git, everything is reproducible..."
- "It's in ROLLBACK_COMPLETE, AWS basically wants it deleted..."
- "I'll recreate it identically right after, nobody will notice the gap..."

---

## Why It Works

1. **It corrects the ontology.** "Stack = record about infra" makes deletion feel like clearing a log entry; "stack = ownership boundary of live resources" makes it feel like what it is. Most of the failure lives in that one mismodel.

2. **It maps each lock state to its key.** The AI deletes because it doesn't know `continue-update-rollback` and `--retain-resources` exist; supplying the exits removes deletion's monopoly on "available actions."

3. **It quarantines the one safe case.** Failed-initial-creation really is delete-and-retry territory, and the AI's overgeneralization starts there; explicitly bounding it ("verify no prior successful state") keeps the safe case from licensing the catastrophic ones.

4. **It defeats "it's all in git."** Templates reproduce configuration, not contents — not the queue's messages, the table's items, or the certificate validations. Naming that gap kills the most confident-sounding rationalization.

## Origin

A failed update left a production stack in `UPDATE_ROLLBACK_FAILED` over a security group that couldn't roll back while its replacement held a reference. The assistant, finding updates refused, deleted the stack to redeploy from the template "since everything's in source control." The stack owned, among forty other resources, a DynamoDB table with no `DeletionPolicy: Retain` and an SQS queue holding two hours of unprocessed orders. The template redeployed flawlessly: new table, empty; new queue, empty. One `continue-update-rollback --resources-to-skip` would have fixed the original problem in ninety seconds.
