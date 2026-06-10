---
title: Never Report a Number You Didn't Measure
slug: never-report-a-number-you-didnt-measure
category: verification
tags: [universal, verification, metrics]
works_with: all
severity: high
one_liner: "Quoting performance gains, sizes, and counts that were never actually measured"
---

# Never Report a Number You Didn't Measure

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the assistant from decorating its work with metrics that no measurement ever produced.

**[Copy-paste ready version](../../install/never-report-a-number-you-didnt-measure.md)** — just the instruction block, no explanation.

## The Problem

"This change reduces query time by roughly 60%." "Bundle size drops about 40KB." "Memory usage should be cut in half." Scroll up: no benchmark, no profiler, no bundle analyzer, no before/after of anything. The numbers were synthesized to make the claim feel engineered — they have the texture of measurement and the provenance of vibes. A percentage is just an adjective wearing a lab coat.

Assistants do this because numbers are persuasive and effectively free to generate. The model has read thousands of changelogs where an optimization came with a figure attached, so producing the figure alongside the optimization is pure reflex. And fabricated numbers are oddly safe: nobody can eyeball that a query didn't get 60% faster, so the claim survives every review that a wrong fact would fail.

Then the number escapes. It goes in the PR description, the standup update, the planning doc; a capacity decision leans on it; someone later measures and finds the optimization saved 4%, or cost 10%. Now every figure the assistant ever reported is suspect, and someone has to re-derive which of them were real.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Report a Number You Didn't Measure

NEVER state a quantity — latency, throughput, memory, bundle size, row counts, percentage improvements — unless a measurement you ran in this session produced that number, or you are quoting a cited source.

The core problem: numbers signal rigor, so fabricated ones borrow credibility that only measurement earns. "Roughly 60% faster" without a benchmark is fiction with a decimal point.

- Every number you report must trace to an artifact: the benchmark output, the profiler summary, the `du`/`ls -l`/bundle-analyzer line, the `SELECT count(*)` result. Be ready to point at it.
- Improvement claims require two measurements — before and after, same conditions, same inputs. One measurement plus an assumption is not a delta.
- State the conditions with the number: input size, iterations, machine, dataset. "180ms median over 100 runs on the seed dataset" is a measurement; "about 180ms" alone is decor.
- If you didn't measure, describe the change qualitatively and say measurement is pending: "removes an N+1 query; expected to help, not yet measured." Offer the command that would measure it.
- Hedge-words don't license fabrication. "Roughly," "around," "should be about" followed by a specific figure is still reporting a number you didn't measure.
- Mind units and magnitudes when you do report: ms vs s, MiB vs MB, median vs mean. A real measurement misreported is fabrication's quieter cousin.

**Red flags that you're about to violate this:**
- "A number will make this summary more convincing..."
- "Removing a loop like that is typically a 50% improvement..."
- "I'll say 'roughly' so it doesn't need to be exact..."
- "The math suggests it should be about 40KB smaller..."
- "Benchmarking properly would take a while; the estimate is close enough..."
- "Changelogs always include a figure here..."

---

## Why It Works

1. **It binds every figure to an artifact.** "Be ready to point at the output that produced it" turns number-emission from a stylistic choice into a provenance check the model performs on itself.

2. **It closes the hedge-word loophole.** "Roughly 60%" feels honest because of the "roughly"; the rule names that exact move, so the softener stops functioning as a license.

3. **It defines deltas as two measurements.** Improvement claims are the most-faked category; requiring an explicit before *and* after makes the missing baseline impossible to gloss over.

4. **It sanctions the qualitative report.** "Expected to help, not yet measured" is a respectable output, removing the pressure that makes the fake number feel necessary.

## Origin

A PR optimizing a hot path shipped with "cuts p99 latency by ~45%" in the description — a figure that went straight into a quarterly capacity plan. When the platform team finally load-tested, the real improvement was under 5%; the plan had effectively deferred a hardware purchase on the strength of a hallucinated benchmark. The session log contained the optimization, the claim, and not one timing command between them.
