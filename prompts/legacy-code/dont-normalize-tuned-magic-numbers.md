---
title: Don't Normalize Tuned Magic Numbers
slug: dont-normalize-tuned-magic-numbers
category: legacy-code
tags: [universal, legacy]
works_with: all
severity: high
one_liner: "Stops rounding of oddly specific constants that were tuned by outages"
---

# Don't Normalize Tuned Magic Numbers

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from "tidying" oddly specific legacy constants — timeouts, batch sizes, pool limits — whose weird values were tuned by production incidents.

**[Copy-paste ready version](../../install/dont-normalize-tuned-magic-numbers.md)** — just the instruction block, no explanation.

## The Problem

Legacy code is full of numbers that look wrong: a timeout of 47 seconds, a batch size of 750, a connection pool of 3, a retry cap of 7, a buffer of 12288. AI assistants itch to normalize these — 47 becomes 30 or 60, 750 becomes 500 or 1000, the pool of 3 becomes "a sensible 10." Sometimes the change rides along with a legitimate task, like extracting the literal into a named constant, and the value gets quietly "corrected" in transit.

But oddly specific values are specific *because they were tuned*. The 47-second timeout sits just above a vendor's worst observed p99 and just below a load balancer's 50-second cutoff. The batch of 750 is the largest size that didn't trip the downstream API's undocumented payload limit. The pool of 3 matches a database license cap or a deliberate concurrency throttle that once stopped a connection storm. Round numbers are defaults; weird numbers are measurements. The weirder the value, the more likely someone bled for it.

Changing a tuned constant doesn't fail fast. It shifts a system's behavior under load — exactly the regime that dev, CI, and code review never exercise — and the regression arrives weeks later as a capacity incident that nobody connects to "cleaned up some constants."

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Don't Normalize Tuned Magic Numbers

NEVER change the value of an oddly specific constant in legacy code — timeout, batch size, pool size, retry count, buffer size, threshold — while renaming, extracting, refactoring, or "tidying" it. Weird values are tuned values: each one was measured against a real constraint, usually during an incident. Round numbers are guesses; specific numbers are scars.

Rules:

- Extracting a literal into a named constant must preserve the value bit-for-bit. `TIMEOUT_SECONDS = 47`, not 45, not 60. The name is yours to improve; the number is not.
- Before changing any tuning value on purpose, `git blame` it. A constant last touched in a commit referencing an incident, a vendor, or load testing is a measurement — changing it requires re-measuring, not preferring a rounder number.
- Treat suspicious specificity as a signal: 47, 750, 12288, and 3 are weird in ways that 30, 1000, 8192, and 10 are not. The weirdness usually encodes a nearby limit (vendor p99, payload cap, license limit, LB timeout). Try to identify the limit before concluding there isn't one.
- Never "align" related constants for symmetry. Three different timeouts in one file are usually three different measured constraints, not sloppiness.
- If a value genuinely needs to change for your task, say so explicitly in your summary with the old value, new value, and reasoning — never change it silently inside a larger diff.

**Red flags that you're about to violate this:**
- "47 seconds is clearly arbitrary, I'll round it to 60."
- "While extracting this constant, I'll set it to a more standard value."
- "A pool size of 3 must be a typo or placeholder."
- "I'll make all these timeouts consistent at 30 seconds."
- "Powers of two are conventional, so 12288 should be 16384."
- "Nobody would notice a small change to a batch size."

---

## Why It Works

1. **"Round numbers are guesses; specific numbers are scars" gives the AI a usable heuristic.** Specificity becomes evidence of tuning rather than evidence of sloppiness — inverting the exact judgment that drives the failure.
2. **It separates the name from the value.** Most tuned-constant damage happens during well-intentioned extraction; making the value immutable through the rename removes the rider without blocking the refactor.
3. **"Identify the nearby limit" converts suspicion into investigation.** A 47-second timeout under a 50-second LB cutoff explains itself once the AI goes looking; the search usually finds the constraint or the commit that names it.
4. **The explicit-change requirement defeats silence.** Tuning regressions are untraceable mainly because the change was buried in a refactor diff; forcing old value, new value, and reasoning into the summary makes the change findable when load behavior shifts.

## Origin

A refactor extracting configuration into a settings module rounded a queue consumer's batch size from 750 to 1000 in passing — flagged by no one, since the diff was about structure, not values. The downstream service rejected payloads above a size that 750-item batches approached but never exceeded; the original engineer had found the ceiling empirically during launch week. At 1000, roughly a third of batches bounced, retried, and re-bounced. Queue lag built for two days before alarming, and the eventual fix was a one-character revert: the kind of incident where the postmortem's timeline is longer than the diff.
