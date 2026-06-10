---
title: Investigate Flaky CI Before Retrying
slug: investigate-flaky-ci-before-retrying
category: ci-cd
tags: [universal, ci, flaky]
works_with: all
severity: medium
one_liner: "Stops blind retries of flaky CI jobs in place of finding the actual cause"
---

# Investigate Flaky CI Before Retrying

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from treating "re-run until green" as a fix for intermittent CI failures.

**[Copy-paste ready version](../../install/investigate-flaky-ci-before-retrying.md)** — just the instruction block, no explanation.

## The Problem

A CI job fails. The AI re-runs it. It passes. Task complete — except nothing was completed. The failure is still in there, now classified as "flaky," which in practice means "a real bug we have agreed to roll dice against." Assistants escalate this pattern quickly: first a manual re-run, then a `retry: 2` key in the job config, then a `nick-fields/retry` wrapper around the test step, until the pipeline is a slot machine that usually pays out.

The cost compounds in two directions. Pipelines get slower and more expensive, because every real failure now runs three times before reporting. And genuine regressions get camouflaged: when a test fails one run in five, a retry-wrapped pipeline will merge the commit that caused it roughly 99% of the time. The flake rate becomes a smuggling channel for real bugs.

The reason assistants default to retrying is that an intermittent failure looks like noise rather than signal, and a re-run is the cheapest action that makes the noise stop. But intermittent failures are signal — about race conditions, test pollution, unpinned dependencies, or resource contention — and they are signal precisely because they're intermittent.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Investigate Flaky CI Before Retrying

NEVER respond to an intermittent CI failure by retrying it — manually, with a `retry:` key, or with a retry-wrapper action — until you have investigated what actually failed. "It passed on re-run" is an observation, not a diagnosis.

Retries convert a visible problem into an invisible tax: slower pipelines, higher CI bills, and real regressions that slip through because failures are presumed flaky.

- When a job fails intermittently, pull the logs from the failing run first. Identify the exact test or step, the error, and the difference from passing runs (timing, ordering, environment).
- Look for the classic causes before declaring flakiness: shared state between tests, time/timezone dependence, network calls to real services, port collisions, unpinned dependency or image versions, and resource exhaustion on the runner.
- If you find the root cause, fix it in the code or test, not in the pipeline.
- If you cannot find the root cause in the time available, say so explicitly and report what you ruled out. Recommend quarantine-with-a-ticket as a human decision; do not silently add retry config.
- Never add a blanket retry to a whole job or workflow. If a retry is ever justified (a documented-unreliable external dependency you cannot remove), scope it to that single operation and comment why.
- One green re-run proves nothing. If you claim something is fixed, the evidence is the cause you found, not the color of the latest run.

**Red flags that you're about to violate this:**

- "It passed when I re-ran it, so the failure was spurious."
- "This test is known to be flaky; everyone just retries it."
- "Adding a retry wrapper is a pragmatic fix while the team is busy."
- "The failure is probably infrastructure, so there's nothing to investigate in the code."
- "Three attempts should be enough to get past this reliably."

---

## Why It Works

1. **It severs "passed on retry" from "fixed."** The assistant's strongest rationalization is that a green re-run is evidence; the rule explicitly downgrades it to an observation requiring explanation.
2. **It supplies an investigation checklist.** Assistants retry partly because they don't know what to look for in an intermittent failure; naming the usual suspects (shared state, timing, real network calls, unpinned versions) makes investigation tractable.
3. **It reframes retries as a smuggling channel for regressions,** not a reliability feature — which matches the actual math of retry-wrapped pipelines.
4. **It routes the genuine quarantine case through a human,** preserving an escape hatch without letting the assistant grant itself one.

## Origin

An assistant was asked to "stabilize CI" for a service whose integration suite failed about one run in four. It wrapped the suite in a three-attempt retry action, and the pipeline went reliably green. The underlying cause was a race in the connection pool — the same race that, eight weeks later, started dropping requests under production load. The retry config had been hiding a load-dependent bug while it got worse, and the team's first question in the postmortem was why CI had never caught it. CI had caught it, repeatedly, and been told to roll again.
