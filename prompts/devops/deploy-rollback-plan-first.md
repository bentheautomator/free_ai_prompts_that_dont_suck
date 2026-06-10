---
title: No Deploy Without a Rollback Plan
slug: deploy-rollback-plan-first
category: devops
tags: [universal, devops, deploys]
works_with: all
severity: critical
one_liner: "Shipping changes with no stated, working way to undo them"
---

# No Deploy Without a Rollback Plan

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from deploying changes whose only undo plan is "fix forward under pressure."

**[Copy-paste ready version](../../install/deploy-rollback-plan-first.md)** — just the instruction block, no explanation.

## The Problem

Ask an AI assistant to deploy and it deploys. Ask it what the rollback is and you'll often get the first honest pause of the session. The deploy path is rehearsed constantly; the rollback path is rehearsed never, and for a meaningful fraction of changes it doesn't exist at all — the deploy ran a destructive migration, the previous image was overwritten, the old launch template was deleted as cleanup, or the change is a config flip nobody recorded the prior value of.

AI assistants make this worse in a specific way: they optimize for completing the requested action. "Deploy this" has a finish line; "be able to undo this" doesn't, unless someone makes it a precondition. So the assistant ships, declares success, and the rollback question first gets asked during the incident — when the answer involves reconstructing the previous state from memory, at 2 a.m., with the error rate graph open in the next tab.

A rollback plan is cheap precisely once: before the deploy. It's three sentences — what was running before, the command that restores it, how long that takes — plus one honest check that the command actually works.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No Deploy Without a Rollback Plan

NEVER execute a deploy without first stating, concretely, how to undo it. "Rollback plan" means three things written down before anything ships: the exact prior state (image tag, config version, infra revision), the exact command that restores it, and roughly how long restoration takes.

- Identify the current version before replacing it: `kubectl get deploy api -o jsonpath='{...image}'`, the live task definition revision, the current Helm release (`helm history`), or the prior git SHA. If you can't name what's running now, you can't roll back to it.
- Verify the rollback target still exists: the old image tag is still in the registry, the previous task definition revision isn't deregistered, the prior config is recoverable. A rollback plan pointing at a deleted artifact is a hope, not a plan.
- Name the one-way doors. Destructive migrations, dropped columns, queue format changes, and deleted resources make rollback impossible or partial — say so explicitly before deploying, and prefer reversible orderings (expand/contract, additive first).
- State what triggers the rollback: which metric or check, watched for how long after the deploy, decides "roll back now."
- Do not delete the previous version's artifacts (old images, launch templates, task definition revisions) as part of deploy cleanup. The previous version is the rollback; keep at least one.
- If a real rollback path doesn't exist for this change, that's a finding to surface, not a detail to omit. Let the human decide to proceed eyes-open.

**Red flags that you're about to violate this:**

- "It's a small change, we'll fix forward if anything breaks..."
- "Rollback is implied, we'd just redeploy the old version somehow..."
- "I'll clean up the old images while I'm at it..."
- "The migration is technically irreversible but it won't fail..."
- "They asked me to deploy, not to write contingency docs..."

---

## Why It Works

1. **It converts "rollback" from vibe to artifact.** Prior state, restore command, duration — three blanks that won't fill themselves with optimism. An unfillable blank is the early warning this rule exists to produce.

2. **It checks that the target exists.** Most rollback "plans" die at "redeploy the previous version" because the previous version was pruned; verifying artifact existence catches that before it matters.

3. **It surfaces one-way doors pre-deploy.** Irreversibility isn't always avoidable, but it should always be announced. Forcing the announcement moves the eyes-open decision to a human, ahead of time.

4. **It defines the rollback trigger.** Without a stated metric and window, rollback decisions happen by argument during the incident; with one, the deploy carries its own abort criteria.

## Origin

A release shipped Friday afternoon with a deploy script that, as a final step, pruned "old" images from the registry to save space. Saturday morning the new version started corrupting a cache shared with another service. The rollback command was ready in seconds; the image it referenced had been deleted by the deploy itself twelve hours earlier. Rebuilding the previous release from source — on a weekend, with a CI pipeline that had since moved on — turned a five-minute rollback into a six-hour incident.
