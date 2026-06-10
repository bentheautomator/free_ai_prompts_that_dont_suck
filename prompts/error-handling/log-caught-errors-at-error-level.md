---
title: Log Caught Errors at Error Level
slug: log-caught-errors-at-error-level
category: error-handling
tags: [universal, errors, logging]
works_with: all
severity: medium
one_liner: "AI recording real failures at debug/info or print, invisible to alerting"
---

# Log Caught Errors at Error Level

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents genuine failures from being recorded at a level that monitoring is configured to ignore.

**[Copy-paste ready version](../../install/log-caught-errors-at-error-level.md)** — just the instruction block, no explanation.

## The Problem

The catch block exists, and it even logs — but it logs `logger.debug(f"sync failed: {e}")`. Production runs at INFO. The failure is being written into the void: filtered out before it reaches a file, an aggregator, or an alert rule. Variants are everywhere in AI-generated code: `print(e)` (goes to stdout, unstructured, no level, often lost entirely under process managers), `console.log(err)` instead of `console.error`, `logger.info("Exception occurred")`, and warnings used for outright failures because "warning" felt politely calibrated.

Log levels aren't tone — they're routing. ERROR is typically what pages people, feeds error-rate dashboards, and triggers Sentry-style capture; DEBUG and INFO are typically discarded or sampled in production. An error logged below ERROR isn't "logged quietly," it's unrouted: the handler has technically recorded the failure while guaranteeing no system or human configured to watch for failures will see it. It's the observability version of swallowing — the catch block gets credit for logging, and the operational outcome is identical to silence.

Models miscalibrate here because level choice looks stylistic. There's no compiler feedback, the line works at any level, and `print` is the lowest-friction token sequence available. The mapping from level to downstream routing exists only in production configs the model never sees.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Log Caught Errors at Error Level

Log levels are routing, not tone. A real failure logged below ERROR is invisible to the alerting and dashboards that watch for failures — record it at the severity that gets it seen.

- A caught exception representing a failed operation is logged at ERROR, with the exception and stack attached: `logger.error("payment sync failed for order %s", oid, exc_info=True)` / `logger.error("sync failed", err)` — not debug, not info, not a message without the exception
- Never use `print(e)` or `console.log(err)` for failures in code that has a logger; use the logger at error level (`console.error` at minimum in plain JS)
- Reserve the lower levels for what they route to: WARN for degraded-but-handled (retry succeeded, fallback engaged deliberately), INFO for normal operations, DEBUG for diagnostics — a failure that broke the operation is none of these
- Don't inflate either: logging expected, handled conditions at ERROR (every cache miss, every validation rejection of user input) trains humans and alert thresholds to ignore the channel — severity inflation and severity deflation both end in missed incidents
- The test for level: who needs to act? Someone should be alerted → ERROR. Worth noticing in review → WARN. Nobody → INFO/DEBUG
- When you downgrade an existing `logger.error` to reduce noise, you are editing alerting behavior; say so explicitly rather than slipping it into an unrelated diff

**Red flags that you're about to violate this:**
- "I'll print the exception so it shows up during testing..."
- "Debug level keeps production logs clean..."
- "It's caught, so warning seems more accurate than error..."
- "console.log is fine; it all goes to the same place..."
- "I don't want this to trigger alerts, so I'll log it lower..."

---

## Why It Works

1. **It replaces tone with routing.** The model picks levels by how severe the message *sounds*; explaining that levels select which systems and humans ever see the line converts a stylistic choice into a functional one with a wrong answer.

2. **It equates under-leveled logging with swallowing.** "Recorded but unrouted" closes the loophole where the model gets credit for a log line that production filters discard — the operational outcome, not the source code, is the standard.

3. **The who-acts test is decidable at the call site.** "Should someone be alerted?" can be answered from local context, unlike "what's the right level," which invites vibes.

4. **It polices both directions.** Inflation is the failure mode of overcorrecting; including it keeps the rule from producing a codebase where everything is ERROR and the channel is worthless anyway.

## Origin

A data team noticed their export feature had been failing for certain customers for six weeks. The handler was conscientious: caught the exception, logged it with full context — at DEBUG, in a service whose production log level was INFO. Error dashboards showed nothing, Sentry showed nothing, and support tickets were triaged as user error because "there are no errors in the logs." The one-character-class fix (`debug` to `error`) was accompanied by a grep that found nineteen other failures being logged into the same void.
