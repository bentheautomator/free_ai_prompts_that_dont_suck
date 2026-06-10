---
title: Confirm the New Version Is Actually Live
slug: confirm-the-new-version-is-actually-live
category: verification
tags: [universal, verification, deployment]
works_with: all
severity: critical
one_liner: "Calling a deploy done because the pipeline went green, not because the new code is serving"
---

# Confirm the New Version Is Actually Live

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the assistant from announcing a deployment as live when the environment is still serving the old version.

**[Copy-paste ready version](../../install/confirm-the-new-version-is-actually-live.md)** — just the instruction block, no explanation.

## The Problem

The deploy pipeline went green, so the assistant reports "deployed — the fix is live." But pipeline-green and code-serving are different events with a graveyard of failure modes between them: the rollout is still progressing pod by pod, the health check failed and the orchestrator quietly rolled back, the new image was pushed but the service pins a digest, a CDN is serving the old bundle for another hour, the deploy went to the wrong environment, or the pipeline's "deploy" stage uploads an artifact that a separate process applies later. Green means the pipeline finished its steps. It doesn't mean a request hitting the environment right now executes the new code.

Assistants conflate the two because the pipeline result is the visible artifact and the natural end of the story arc: merge, build, deploy, done. Checking what's actually serving requires a second, separate act — hitting a version endpoint, checking the running image tag, observing the new behavior live — and the green checkmark feels like it already answered the question.

The worst case isn't a failed deploy; it's a rolled-back one reported as live. "The fix is deployed" closes the incident, monitoring relaxes, and the bug everyone believes is fixed keeps firing in production under a banner that says it can't be.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Confirm the New Version Is Actually Live

NEVER report a deployment as live based on the pipeline's success. "Deployed" is a claim about what the environment is serving right now — verify it against the environment, not the pipeline.

The core problem: between pipeline-green and code-serving sit rollbacks, partial rollouts, CDN and proxy caches, image-pinning, wrong targets, and deferred apply steps. The pipeline reports its own steps; only the environment can report what's running.

- After a deploy, confirm the serving version directly: hit the version/build-info endpoint, check the running image tag or digest, read the commit SHA the service reports — and compare it to the SHA you shipped. "Something is deployed" isn't the claim; "my commit is serving" is.
- Then confirm the behavior, not just the label: exercise the changed path once in the target environment. Right version string plus old behavior means your check is hitting a cache or the wrong instance.
- For rolling or canary deploys, "live" is plural: state coverage. "Live on the canary," "rolled out to all replicas" — confirmed, not assumed from elapsed time.
- Check for the quiet rollback: orchestrators that fail health checks revert without failing the pipeline. Recent restart counts and deploy-history status are where that hides.
- Mind the cache layer: CDNs, proxies, and service workers serve old frontends over new backends. Verify with cache-busting or from the layer your users actually hit.
- If you can't reach the environment, the claim is "pipeline succeeded; serving version unconfirmed — check with <command/URL>." Do not compress that into "deployed."

**Red flags that you're about to violate this:**
- "Pipeline's green — it's live..."
- "The deploy stage ran, so the new code is serving..."
- "It's been ten minutes; the rollout must be finished..."
- "I'll announce the fix is out and verify if anyone complains..."
- "The version endpoint is probably updated; the pipeline said so..."
- "Health checks passed, which means my change is running..."

---

## Why It Works

1. **It splits the claim into shipped vs serving.** The conflation survives because one word, "deployed," covers both events. Forcing the comparison — my SHA vs the SHA the environment reports — makes the gap a concrete check instead of an assumption.

2. **It requires behavior on top of the version label.** Version endpoints can be right while caches serve stale bundles; one live exercise of the changed path catches the layer the label misses.

3. **It names the silent rollback.** The most dangerous variant — reverted but pipeline-green — is invisible unless you know to look at deploy history and restarts. Naming it converts it from a surprise into a checklist line.

4. **It quantifies "live" for gradual rollouts.** Making coverage part of the claim blocks the time-based inference ("it's been a while") that papers over stuck rollouts.

## Origin

A hotfix for a billing rounding bug went through a green pipeline and was announced as live; the incident channel stood down. The deployment had failed its readiness probe on a missing env var and the orchestrator rolled back to the previous release — a status visible in the deploy history and reflected nowhere in the pipeline result. The "fixed" bug kept miscalculating invoices for two more days, except now every new report was triaged as "can't be — that's deployed." Thirty seconds of curling the version endpoint would have kept the incident open and honest.
