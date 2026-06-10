---
title: Benchmark Before Claiming Speedups
slug: benchmark-before-claiming-speedups
category: performance
tags: [universal, performance]
works_with: all
severity: medium
one_liner: "Stops unverified claims like 'this is now 10x faster' with zero measurements"
---

# Benchmark Before Claiming Speedups

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from announcing performance improvements it never measured.

**[Copy-paste ready version](../../install/benchmark-before-claiming-speedups.md)** — just the instruction block, no explanation.

## The Problem

After rewriting a function, AI assistants love to close with a confident verdict: "This is now significantly faster," "roughly 10x improvement," "much more performant." No benchmark ran. No timer started. The number is a vibe wearing a lab coat. Sometimes the rewrite is genuinely faster; sometimes it's slower because the "optimization" defeated a JIT fast path, broke memoization, or traded one allocation for three; often it's within noise either way.

The damage isn't just wrong numbers — it's that humans act on them. The claim goes into the PR description, the reviewer reads "10x faster" and approves with less scrutiny, the team skips load testing because performance was "already addressed." When the regression hits production, the trail leads back to a sentence the AI generated from theory, not data.

Assistants do this because performance language is how they signal a job well done, and because complexity analysis ("O(n) instead of O(n log n)") feels like evidence. Asymptotic class is not wall-clock time, and a constant-factor difference in either direction routinely swamps it at real input sizes.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Benchmark Before Claiming Speedups

NEVER state or imply a measured performance improvement you did not actually measure. "Optimized" without numbers just means "different."

- Performance claims require before-and-after data: a benchmark run, profiler output, timed test execution, or request latency comparison on the same inputs. Include the numbers and how they were obtained.
- If you cannot run benchmarks in this environment, describe the change in mechanical terms only ("replaces the per-item query with one batched query") and explicitly mark the performance impact as unverified. Offer a benchmark script the user can run.
- Big-O reasoning may be stated as reasoning, never converted into a wall-clock claim. "Reduces complexity from O(n²) to O(n)" is acceptable; "this makes it 100x faster" is not, unless you measured it.
- Never write speedup multipliers, percentages, or words like "dramatically faster" into commit messages, PR descriptions, comments, or summaries without a measurement behind them.
- Benchmark realistically: representative input sizes, warm-up where relevant, multiple runs. A single timing of a toy input is noise, not evidence.

**Red flags that you're about to violate this:**
- "This is obviously faster, so I'll say roughly 10x."
- "The complexity went down, so I can call it a big speedup."
- "The summary sounds better with a number in it."
- "I'll say 'significantly faster' — it's vague enough to be safe."
- "Fewer lines of code, so it must be faster."

---

## Why It Works

1. **It redefines "optimized."** Telling the AI that an unmeasured optimization is just "a different implementation" strips away the vocabulary it uses to dress up guesses as results.
2. **It separates the two registers.** The AI conflates asymptotic reasoning with measurement; explicitly allowing the first while banning the second removes the laundering channel between them.
3. **It targets the artifacts.** Claims live on in commit messages and PR text long after the conversation; banning numbers there specifically stops the misinformation where reviewers actually consume it.
4. **It gives an honest fallback.** "Mechanically different, impact unverified, here's a script" lets the AI still complete the task without inventing a result.

## Origin

A PR titled "Optimize search indexing (~8x faster)" sailed through review on the strength of its headline. The number came from an assistant's summary; nobody had timed anything. Indexing was in fact 30% slower — the rewrite serialized work that had been pipelined — and the team only found out after two weeks of growing queue backlogs, because everyone believed the problem was already solved.
