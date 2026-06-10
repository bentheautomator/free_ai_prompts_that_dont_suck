---
title: No IAM Wildcards to Unblock a Deploy
slug: no-iam-wildcards-to-unblock-deploys
category: devops
tags: [universal, devops]
works_with: all
severity: high
one_liner: "Granting Action star on Resource star because the deploy hit AccessDenied"
---

# No IAM Wildcards to Unblock a Deploy

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from solving one AccessDenied with a policy that grants everything, forever, to whatever hit the error.

**[Copy-paste ready version](../../install/no-iam-wildcards-to-unblock-deploys.md)** — just the instruction block, no explanation.

## The Problem

An `AccessDenied` during a deploy is a precise message: this principal lacked this action on this resource. It even tells you which. The AI's fix, an alarming amount of the time, is maximally imprecise: `"Action": "s3:*"` — or when that still fails because the error moved, `"Action": "*", "Resource": "*"` attached to the deploy role, the task role, or whatever was complaining. The deploy goes green, the diff looks like config plumbing, and the infrastructure now contains a principal that can do anything to everything, created not by a security decision but by error-message whack-a-mole.

Assistants escalate to wildcards because permission errors arrive one at a time, and each iteration of "add the missing permission, re-run, hit the next error" feels slower than ending the game in one move. They also genuinely struggle to predict the full permission set a deploy needs, so the wildcard is a hedge against their own uncertainty. But IaC makes this worse than a console mistake: the wildcard is now *codified*, reviewed once in a hurry, and inherited by every future apply. Overgranted roles are the raw material of every cloud breach writeup — the bug gets you in, the role takes you everywhere.

The narrow fix is nearly always knowable: the denied action is in the error, the resource ARN is in the error, and policy simulators or access analyzers can confirm the rest.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No IAM Wildcards to Unblock a Deploy

NEVER fix a permission error by granting `Action: "*"`, service-level wildcards (`s3:*`, `iam:*`), or `Resource: "*"`. An AccessDenied names the exact action and resource that were denied; the fix is exactly that grant, scoped to exactly that resource.

- Read the error: it contains the principal, the action (`s3:PutObject`), and usually the ARN. Grant that action on that ARN (or a tight prefix like `arn:aws:s3:::deploy-artifacts/*`), nothing wider.
- Permission errors arriving one at a time is normal. Iterating three times on narrow grants beats one wildcard; if iteration is impractical, derive the needed set from the service's documented actions for the operation, or from CloudTrail/IAM Access Analyzer data on what the role actually calls — then grant that list.
- Treat certain actions as red-line, never granted as collateral: `iam:*` (privilege escalation), `iam:PassRole` un-scoped, `kms:*`, `sts:AssumeRole` on `*`, and any `Delete*`/`Put*Policy` the workflow doesn't demonstrably perform.
- Never widen a *different* principal's policy because it's the one you can edit; fix the principal that was denied.
- If a wildcard already exists in the policy you're editing, don't extend the pattern ("the role already has `s3:*`, so `dynamodb:*` is consistent"). Flag it instead.
- A temporary wildcard "to confirm permissions are the issue" counts as a violation the moment it's applied to a shared environment; use the IAM policy simulator for that experiment instead.

**Red flags that you're about to violate this:**

- "I keep hitting new AccessDenied errors, a wildcard ends the loop..."
- "I can't enumerate everything the deploy will need..."
- "It's only the staging role..."
- "s3:* on one bucket's resources is basically scoped..."
- "The role next to it already has admin, this is no worse..."

---

## Why It Works

1. **It points at the information already in hand.** The AI wildcards because it feels uncertain, but the denied action and ARN are sitting in the error text; the rule converts "unknowable permission set" into "read the message you just received."

2. **It legitimizes iteration.** The real pressure is that narrow grants take multiple rounds; explicitly blessing the three-iteration loop (and naming CloudTrail/Access Analyzer as accelerators) removes the time excuse.

3. **It red-lines the escalation primitives.** `iam:PassRole` and friends are how a wide role becomes total compromise; calling them out individually means even a "scoped" policy can't smuggle them in as neighbors.

4. **It stops pattern propagation.** Existing wildcards teach the AI the house style; the flag-don't-extend clause breaks the copy-the-neighbor mechanism that makes overgranting compound.

## Origin

A CI deploy role hit `AccessDenied` on `ecs:RegisterTaskDefinition`. After two more denials in the same run, the assistant attached a managed `PowerUserAccess`-equivalent inline policy "temporarily" and the deploy passed; the diff was approved among forty other lines. Eight months later a compromised CI plugin used that role to read every secret the account's parameter store held — the breach writeup's longest section was titled "How the deploy role came to have these permissions," and the answer was: nobody decided. An error loop did.
