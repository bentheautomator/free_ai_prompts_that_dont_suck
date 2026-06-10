---
title: Roll Out Gradually, Not Big Bang
slug: roll-out-gradually-not-big-bang
category: devops
tags: [universal, devops, deploys]
works_with: all
severity: high
one_liner: "Replacing 100% of running instances with the new version in one step"
---

# Roll Out Gradually, Not Big Bang

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from configuring deploys where the first user to test the new version is every user.

**[Copy-paste ready version](../../install/roll-out-gradually-not-big-bang.md)** — just the instruction block, no explanation.

## The Problem

Left to choose a rollout strategy, AI assistants choose "all of it, now." They write deploy scripts that stop the old version and start the new one. They set `strategy: Recreate` in Kubernetes manifests because it's simpler than reasoning about surge math. They configure `maxUnavailable: 100%` or replace an entire ASG in one batch. They "speed up" an existing canary pipeline by removing the bake time, because the task said deploy and the canary was making deploy slow. Each of these collapses the single most valuable property a deploy can have: a phase where the new version serves a small fraction of traffic while someone — or something — checks whether it's on fire.

Big-bang exposure interacts brutally with the math of partial failures. A bug affecting 2% of requests on a 5% canary is a metric anomaly; the same bug at 100% is an incident with customers in it. Gradual rollout doesn't prevent bad code from shipping — it caps the blast radius during the window when you know the least about the new version's behavior under real traffic.

Assistants default to big bang because it is genuinely simpler: no surge capacity to reason about, no version-skew concerns, no waiting. All real costs, all deferred, all somebody else's pager.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Roll Out Gradually, Not Big Bang

NEVER configure or execute a deploy that replaces all serving capacity in one step. New code's first contact with production traffic must be partial, observed, and abortable.

- In Kubernetes, default to `RollingUpdate` with `maxUnavailable: 0` and a modest `maxSurge` (e.g. 25%); never set `strategy: Recreate` for a traffic-serving Deployment unless the app genuinely cannot run two versions concurrently — and say so if that's the claim.
- Between phases, observe: error rate, latency, and the deploy-relevant metric, for long enough to mean something (minutes of real traffic, not "the pods are Ready"). Readiness gates catch crash loops; only traffic catches wrong answers.
- Use the platform's native gradual mechanisms instead of hand-rolling: ASG instance refresh with batch sizes and health checks, weighted target groups, CodeDeploy/Argo Rollouts canary steps, per-service traffic splitting.
- Never remove, shorten, or skip an existing canary phase, bake time, or rollout pause to make a deploy faster — those settings are someone's post-incident scar tissue. Changing them is its own reviewed change, not a deploy-time convenience.
- Version skew is a feature requirement, not an excuse: if old and new genuinely can't coexist (schema, protocol), the fix is expand/contract sequencing, not Recreate.
- Big-bang is occasionally legitimate (single-replica services, true breaking cutovers, emergency patches). Name the reason, state the blast radius — "all traffic moves at once; rollback takes N minutes" — and get the human's yes.

**Red flags that you're about to violate this:**

- "Recreate is cleaner, no version-skew headaches..."
- "The change is tiny, a canary phase is ceremony..."
- "Tests passed, gradual rollout just delays the same outcome..."
- "I'll set the canary wait to zero so the pipeline finishes in this session..."
- "Both versions briefly running might cause weirdness, safer to stop everything first..."

---

## Why It Works

1. **It locates the value of gradualism precisely.** "The window when you know the least" reframes canaries from bureaucracy to information-gathering, which dismantles "tests passed, so the canary adds nothing."

2. **It pre-defends existing safeguards.** AIs degrade canary configs far more often than they design deploys from scratch; making bake times scar tissue with their own change process protects the settings under deadline pressure.

3. **It cuts off the version-skew escape hatch.** Skew is the one technically respectable argument for Recreate; routing it to expand/contract turns the excuse into an engineering task.

4. **It requires observation between phases, defined by traffic.** "Pods Ready" is the false-positive the AI loves; tying phase advancement to served-traffic metrics makes the partial phase actually do its job.

## Origin

A team's deploy pipeline had a 10% canary with a 15-minute bake — until an assistant, asked to "make deploys less painful," identified the bake time as the painful part and zeroed it out. The change sailed through review as pipeline cleanup. Four deploys later, a release with a connection-leak bug went 10%-to-100% in under a minute, exhausted the database connection pool, and took down the platform — including the dashboard that would have shown the canary failing, back when there was time to care.
