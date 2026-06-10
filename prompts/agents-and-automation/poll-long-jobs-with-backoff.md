---
title: Poll Long Jobs With Backoff
slug: poll-long-jobs-with-backoff
category: agents-and-automation
tags: [universal, agents, loops]
works_with: all
severity: medium
one_liner: "Checking CI status every ten seconds for forty minutes straight"
---

# Poll Long Jobs With Backoff

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the agent from hammering a long-running job with status checks every few seconds until the wait costs more than the work.

**[Copy-paste ready version](../../install/poll-long-jobs-with-backoff.md)** — just the instruction block, no explanation.

## The Problem

The agent kicks off a CI run, a deploy, or a long build, and then it has to wait — which agents are spectacularly bad at. The default behavior is to check the status immediately, see "in progress," check again, see "in progress," and keep checking on a tight cadence for the entire duration. A twenty-minute pipeline becomes a hundred and twenty status calls, each one adding a near-identical blob of JSON to the context window and, for metered APIs, a line item to the bill.

This happens because an agent's only way to experience time passing is to take an action, and a status check is the most available action. There's no internal clock saying "this build historically takes eighteen minutes; checking before minute fifteen is pointless." Every poll feels like diligence. Collectively they're a denial-of-service attack on the agent's own context — and occasionally on someone's rate limit.

The damage is quiet but cumulative: by the time the job finishes, the transcript is a wall of identical status payloads, and the context that explained why the job was launched has been squeezed toward the exit.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Poll Long Jobs With Backoff

NEVER poll a long-running job on a tight, fixed interval. Estimate the job's duration first, wait most of it out, then poll with increasing gaps.

The core problem: checking status is the only way you feel time pass, so you check constantly — and every identical "in progress" response burns context and API calls while telling you nothing.

- Before waiting on any job, estimate its duration from evidence: previous runs in this session, CI history, or the nature of the task (a deploy is minutes, not seconds). State the estimate.
- Do not check at all until roughly 80% of the estimate has elapsed. Then poll with backoff: if it's still running, double the gap between checks.
- Use blocking waits when they exist: `gh run watch`, `kubectl rollout status`, `wait` commands, webhooks, or any flag that returns when the job completes. One blocking call beats fifty polls.
- When you must poll, make each check cheap: request the status field, not the full run object with logs. Never pull complete logs until the job has actually finished or failed.
- Fill the wait productively or end your turn: work on an independent subtask, or tell the user "the deploy takes ~15 minutes; I'll check at 14:32." Idle polling is not a use of the wait — it is the destruction of it.
- If a job exceeds twice your estimate, stop polling and investigate once: is it stuck, queued, or genuinely slow? Report rather than resuming the hammer.

**Red flags that you're about to violate this:**
- "Let me check if it's done yet..." (you checked 20 seconds ago)
- "I'll keep an eye on it with frequent checks..."
- "Still running — checking again right away..."
- "I'll fetch the full run details each time so I don't miss anything..."
- "There's nothing else to do while I wait..." (then end the turn with a time estimate)

---

## Why It Works

1. **It gives the agent a clock substitute.** Agents poll because action is their only timekeeping. Requiring a stated duration estimate and an 80% quiet period replaces "check to feel time" with "compute when checking becomes useful."

2. **It installs backoff as a ratchet.** Doubling the gap after each "in progress" makes over-polling self-correcting instead of self-reinforcing.

3. **It redirects to blocking primitives.** Most platforms already solved this with watch/wait commands; pointing at them converts a behavioral problem into a tooling choice.

4. **It bounds the pathological case.** The 2x-estimate investigation rule means a hung job produces one diagnosis, not three more hours of polling.

## Origin

An agent triggered a pipeline known to take about twenty-five minutes, then called the CI status API every fifteen seconds until it finished — just over a hundred calls, each returning the full run object including annotations. The status payloads consumed most of the remaining context window, and when the pipeline finally went green, the agent no longer had the deployment checklist in context and asked the user to re-paste it. The platform's CLI had a `watch` flag the whole time.
