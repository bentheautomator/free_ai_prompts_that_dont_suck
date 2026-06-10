---
title: Don't Bump CI Timeouts to Hide Slowness
slug: dont-bump-ci-timeouts-to-hide-slowness
category: ci-cd
tags: [universal, ci]
works_with: all
severity: medium
one_liner: "Stops timeout increases that paper over runaway jobs and creeping builds"
---

# Don't Bump CI Timeouts to Hide Slowness

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from raising `timeout-minutes` to make a slow or hung job pass instead of finding out why it got slow.

**[Copy-paste ready version](../../install/dont-bump-ci-timeouts-to-hide-slowness.md)** — just the instruction block, no explanation.

## The Problem

A job that used to finish in 12 minutes starts hitting its 20-minute timeout. There are two possible responses: figure out what changed, or change `timeout-minutes: 20` to `timeout-minutes: 45`. AI assistants overwhelmingly pick the second one, because it is a one-line diff that turns red into green, and "make the pipeline pass" is the goal they've silently adopted in place of "make the build healthy."

The timeout was not the bug. The timeout was the alarm. A test suite that doubled in runtime usually means a deadlock, an accidental network call in a unit test, a retry loop hammering a dead service, or a dependency that started downloading the world. Raising the timeout doesn't fix any of those — it just delays the page. And it compounds: 20 becomes 45 becomes 90, every CI minute costs money, and the feedback loop for every developer on the team gets slower with each bump.

The pattern shows up in every CI system: `timeout-minutes` in GitHub Actions, `timeout: 2h` in GitLab, `options { timeout(time: 90) }` in Jenkins. Same move, same lie.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Don't Bump CI Timeouts to Hide Slowness

NEVER raise a CI job or step timeout to make a job that is timing out pass. A timeout firing is a signal that something got slower or hung; raising the limit silences the signal without touching the cause.

A timeout is an alarm, not a constraint to be negotiated with. Treat a newly-hit timeout exactly like a failing test.

- When a job hits its timeout, profile it first: compare step durations against a recent passing run and identify which step grew or hung.
- Look for the usual suspects: a hung process waiting on input, a test making real network calls, a retry loop against a dead endpoint, dependency resolution that stopped hitting cache.
- Fix the slowness at the source — kill the hang, mock the network call, restore the cache — and leave the timeout where it is, so it can catch the next regression.
- If runtime grew for a legitimate, explained reason (a genuinely larger test suite, a new build target), raise the timeout by the measured amount plus modest headroom, and say in the PR description what grew and why.
- Never remove a timeout entirely. A job with no timeout and a hang holds a runner hostage until the platform's ceiling kills it, hours later.
- Do not relocate the problem by splitting the slow step into a separate job with a huge timeout. That is the same bump wearing a disguise.

**Red flags that you're about to violate this:**

- "The job just needs a little more time."
- "CI runners are probably slow today; doubling the timeout is harmless."
- "I'll bump it now and investigate the slowness in a follow-up."
- "There's no time to profile the build; the user wants this merged."
- "Other jobs in this repo have 90-minute timeouts, so 45 is conservative."

---

## Why It Works

1. **It reframes the timeout as an alarm.** Once the timeout is understood as a regression detector rather than an arbitrary limit, raising it is recognizably the same act as deleting a failing assertion.
2. **It demands a measurement before a change.** "Compare step durations against a passing run" converts a vague instinct ("needs more time") into a concrete diagnostic step that usually surfaces the real cause in one look.
3. **It permits legitimate raises with a paper trail.** Timeouts do sometimes need to grow. Requiring the measured cause in the PR description keeps the honest path open while making the lazy path visibly dishonest.
4. **It pre-names the "runners are slow today" excuse**, which is the single most common rationalization and almost never true two runs in a row.

## Origin

A nightly integration job crept from 15 minutes to timing out at 30. An assistant bumped the timeout to 60, then to 120 three weeks later. The actual cause was a test fixture that had started downloading a 2 GB dataset on every run after a cache key change. By the time someone profiled it, the team had burned a month of doubled CI bills and the "fast feedback" suite took two hours.
