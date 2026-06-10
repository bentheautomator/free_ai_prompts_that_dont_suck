---
title: Don't Delete Slow-Looking Code Without Proof
slug: dont-delete-slow-looking-code-without-proof
category: performance
tags: [universal, performance]
works_with: all
severity: critical
one_liner: "Stops removing sleeps, retries, and throttles that were load-bearing"
---

# Don't Delete Slow-Looking Code Without Proof

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from "optimizing away" delays, throttles, and redundant-looking calls that were quietly holding the system together.

**[Copy-paste ready version](../../install/dont-delete-slow-looking-code-without-proof.md)** — just the instruction block, no explanation.

## The Problem

Some of the slowest-looking lines in a codebase are doing the most work. A `sleep(2)` between retries is backoff protecting a downstream service. A `time.sleep(0.1)` in a polling loop is the only thing keeping CPU under 100%. A "redundant" second fetch is a read-after-write consistency check. A throttle on an export job is the contract that keeps a partner API from banning your account. To an AI assistant doing a performance pass, every one of these is a free win: delete the sleep, drop the throttle, remove the duplicate call, declare the code faster.

The assistant does this because the code's purpose is invisible in the code. `sleep(2)` carries no annotation saying "removing this will hammer the payment provider at 400 requests per second." Slow-looking constructs match the textbook definition of waste, and deleting them produces an instant, demonstrable speedup in any local test, so the change looks like a pure improvement right up until production traffic arrives.

The consequence is asymmetric: the speedup is small and the failure is enormous. Removing a 100ms throttle saves 100ms per item and turns a polite batch job into a self-inflicted denial of service against your own database or a third party with a rate limiter and a long memory.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Don't Delete Slow-Looking Code Without Proof

NEVER remove or shorten a sleep, delay, retry backoff, throttle, rate limiter, debounce, lock-wait, or "redundant" call as a performance improvement without first proving why it exists and that nothing depends on it. Slowness in old code is frequently load-bearing.

Code that intentionally wastes time is usually protecting something: a downstream rate limit, a race window, an eventual-consistency lag, a CPU budget, a contractual QPS cap.

- Before deleting, investigate: `git blame` the line, read the commit message and linked ticket, search the codebase and docs for why it was added. If the history says "fix" or references an incident, assume it is load-bearing.
- Ask what breaks if it's gone: who receives the extra throughput? A database, a third-party API, a queue consumer? If you can't name the absorber and its capacity, you can't remove the limiter.
- A duplicate-looking read or refresh may be a deliberate consistency or cache-busting step. Verify with the surrounding logic before calling it redundant.
- If the delay really is obsolete, say so with evidence in the change description ("the downstream cap was lifted in v3 of the API, see X") and keep the removal in its own commit so it can be reverted alone.
- Never bundle these removals silently into a larger refactor. Flag them to the user explicitly.

**Red flags that you're about to violate this:**
- "This sleep is obviously just leftover debugging."
- "Removing the delay is the easiest speedup in this file."
- "It fetches the same thing twice, that has to be a bug."
- "There's no comment explaining it, so it can't be important."
- "My local run is much faster without it and nothing broke."
- "Rate limiting should be the server's problem, not ours."

---

## Why It Works

1. **It inverts the default reading of intentional slowness.** The AI's prior is "delay equals waste"; the rule installs "delay equals protection until proven otherwise," which changes what deletion requires.
2. **It demands a named absorber.** Forcing the question "who takes the extra load?" converts a local code judgment into a systems question the AI cannot answer by reading one file, so it must investigate or ask.
3. **It uses history as evidence.** `git blame` plus commit messages is a concrete, checkable verification step, replacing "no comment, so it's safe" with actual provenance.
4. **It isolates the blast radius.** Requiring a standalone, flagged commit means even a wrong call is a one-line revert instead of an archaeology project inside a 30-file refactor.

## Origin

During a cleanup pass, an assistant removed a `sleep(0.25)` from a webhook fan-out loop, noting it "served no purpose." It was the pacing that kept outbound calls under a partner's 5-requests-per-second contract. The next bulk event burst sent 1,200 webhooks in four seconds; the partner's gateway auto-banned the integration key, and re-enablement took three business days of support tickets. The git history had the answer the whole time: the line's commit message read "throttle fan-out per partner SLA."
