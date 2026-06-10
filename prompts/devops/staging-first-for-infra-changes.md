---
title: Stage Infra Changes Before Prod, Keep Environments Twins
slug: staging-first-for-infra-changes
category: devops
tags: [universal, devops]
works_with: all
severity: high
one_liner: "Applying infra changes straight to prod, or only to prod, breaking env parity"
---

# Stage Infra Changes Before Prod, Keep Environments Twins

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from testing infrastructure changes on production first, or fixing prod alone and quietly turning staging into a different system.

**[Copy-paste ready version](../../install/staging-first-for-infra-changes.md)** — just the instruction block, no explanation.

## The Problem

When a user reports a production problem, the AI's attention goes to production — and so does its fix. It applies the Terraform change to the prod workspace, edits the prod values file, scales the prod node group. The change works, the task closes, and staging never hears about it. Do this a dozen times and staging is no longer a model of production; it's a museum of production as it stood last quarter. Every future "it passed in staging" is now partially fiction, and the next change that staging validates cleanly will fail in prod for a reason staging structurally cannot reproduce.

The mirror-image failure happens at change time: the AI applies a risky infra change — an engine upgrade, a new ingress controller, a VPC modification — directly to production because production is where the user pointed. Staging exists precisely to absorb the first attempt of exactly these changes, and the AI skips it because nothing in the request said "rehearse first."

Both failures share a root: the AI sees environments as independent targets rather than as one system definition deployed twice. Parity isn't a tidiness preference. It's the entire epistemic basis for believing a staging pass predicts a prod pass.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Stage Infra Changes Before Prod, Keep Environments Twins

ALWAYS land infrastructure changes in staging before production, and ALWAYS propagate prod-only emergency fixes back to staging. Environments are one definition deployed multiple times; any change that touches only one environment is creating a lie that a future deploy will believe.

- Default order for any infra change: staging first, verify (actually verify — exercise the changed path, not just "apply succeeded"), then prod with the identical diff. If the change can't be expressed as the same code applied to both, say so before proceeding.
- When asked to fix something "in prod," check whether staging shares the flaw. It usually does; fix both, staging first unless the prod incident is active.
- After any prod-first emergency change, immediately apply the same change to staging in the same session. A prod hotfix without the staging backport is parity debt with no ticket.
- Keep differences declarative and minimal: instance sizes and replica counts may differ via per-env variables, but topology, versions, and configuration structure should not. Never introduce a structural difference (a resource that exists in one env only, a different engine version) as a side effect of a task.
- Before a high-risk prod change (engine upgrades, networking changes, controller swaps), state where it was rehearsed. "Nowhere" is sometimes the true answer; it should be said out loud, not discovered.
- If no staging environment exists for what you're changing, surface that as a finding rather than silently going straight to prod.

**Red flags that you're about to violate this:**

- "The problem is in prod, so prod is where the fix goes..."
- "Staging is probably already different anyway..."
- "I'll backport this to staging in a follow-up..."
- "It's a low-risk change, rehearsal would be theater..."
- "Staging is smaller, so the change wouldn't tell us much there..."

---

## Why It Works

1. **It defines parity as the basis of prediction.** "Staging mirrors prod" sounds like housekeeping; "a staging pass only predicts prod if they match" names the actual stake, which survives cost-benefit pressure much better.

2. **It makes backporting non-optional and immediate.** "Follow-up later" is where parity goes to die; binding the staging fix into the same session converts an intention into a step.

3. **It forces the rehearsal question into the open.** Often the real problem is that nobody can rehearse the change anywhere. The rule doesn't forbid proceeding — it forbids proceeding while pretending otherwise.

4. **It distinguishes parameter differences from structural ones.** Allowing size deltas while banning topology deltas gives the AI a workable line instead of an absolutism it would quietly abandon.

## Origin

Over a few months of incident-driven work, an assistant applied seven fixes directly to a production Kubernetes cluster — a tweaked ingress annotation, a new node taint, a bumped connection-pool setting, each reasonable, none mirrored to staging. Then a major version upgrade was tested in staging, passed cleanly, and took prod down on rollout: the failure involved the ingress annotation that existed in prod only. The team's confidence in staging had been quietly spent down to zero, one unbackported hotfix at a time, and the upgrade just presented the bill.
