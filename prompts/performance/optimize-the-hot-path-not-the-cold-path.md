---
title: Optimize the Hot Path, Not the Cold Path
slug: optimize-the-hot-path-not-the-cold-path
category: performance
tags: [universal, performance]
works_with: all
severity: high
one_liner: "Stops micro-optimizing startup code while the per-request loop burns CPU"
---

# Optimize the Hot Path, Not the Cold Path

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from spending its optimization effort on code that runs once while ignoring the code that runs a million times.

**[Copy-paste ready version](../../install/optimize-the-hot-path-not-the-cold-path.md)** — just the instruction block, no explanation.

## The Problem

Ask an AI assistant to "make this service faster" and watch where it goes: it rewrites the argument parser, tightens the startup config loader, swaps a list comprehension in a CLI helper for a generator. All of that code runs exactly once per process. Meanwhile the request handler that executes 500 times per second still re-serializes the same payload three times per call. The assistant optimized what it could see and understand quickly, not what the process actually spends time in.

This happens because AI assistants pattern-match on "code that looks slow" rather than "code that runs often." A nested loop in an init function looks identical to a nested loop in a request handler. Without frequency information, the assistant treats every function as equally worth optimizing, and cold code is usually simpler to "improve," so it gets improved first.

The result is the worst of both worlds: real diffs, real review burden, real risk of regression, and zero measurable change in latency or cost. Total time is frequency times cost per call. Shaving 80% off something that runs once saves microseconds per day; shaving 5% off the per-request path saves real money.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Optimize the Hot Path, Not the Cold Path

NEVER optimize a code path without first establishing how often it executes. Effort goes where time is actually spent: frequency times cost per call, not how slow the code looks.

The failure: optimizing startup code, CLI glue, error paths, and admin endpoints — code that runs once or rarely — while the per-request or per-item path keeps burning CPU on every single execution.

- Before touching any function, answer: how many times does this run per request, per job, or per day? Once at startup? Once per request? Once per row of a 10M-row table? Write the answer down.
- Code that runs once per process (imports, config parsing, connection setup, CLI argument handling) is almost never worth optimizing. A 200ms startup is invisible; 2ms extra per request at 1000 rps is 2 CPU-seconds per second.
- Inner loops, request handlers, serializers, and per-item callbacks are where multipliers live. Look there first.
- Verify with frequency data: a profiler's cumulative time, a request counter, or log-line counts. "This function looks expensive" is not evidence; "this function accounts for 40% of wall time under production-shaped load" is.
- If the user asks to optimize a cold path specifically, say it's cold and ask whether the per-call savings actually matter before doing it.

**Red flags that you're about to violate this:**
- "This startup function has an obvious inefficiency, I'll fix it while I'm here."
- "Every little bit helps."
- "I don't have a profile, but this nested loop looks bad."
- "Optimizing the init code is lower risk than touching the request handler."
- "The user said make it faster, and this was the easiest thing to make faster."

---

## Why It Works

1. **It forces the multiplication.** "Frequency times cost" turns a vague instinct into arithmetic the AI must perform before editing, which immediately exposes that a once-per-boot function cannot dominate anything.
2. **It names the substitution error.** The AI swaps "runs often" for "looks slow" because the latter is visible in source. Calling out that substitution explicitly breaks the pattern-match.
3. **It demands frequency evidence, not style judgment.** Requiring a per-request or per-day count makes "this looks inefficient" inadmissible as a reason to edit.
4. **It pre-authorizes pushback.** Letting the AI tell the user "that path is cold" prevents compliant optimization of code that doesn't matter.

## Origin

A team asked their assistant to reduce API latency. It delivered a tidy PR: faster YAML config parsing, a memoized environment lookup, a rewritten startup banner. All real improvements to code that ran once per deploy. P99 latency didn't move, because the actual cost was a JSON re-encode happening twice in the response middleware on every request. One engineer with a profiler found it in twenty minutes; the fix was four lines. The assistant's PR had been thirty files.
