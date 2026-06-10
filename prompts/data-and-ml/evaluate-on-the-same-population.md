---
title: Evaluate on the Same Population
slug: evaluate-on-the-same-population
category: data-and-ml
tags: [universal, ml, evaluation]
works_with: all
severity: high
one_liner: "Metrics from different filters or windows are different questions, not a trend"
---

# Evaluate on the Same Population

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents comparing metrics computed on differently-filtered, differently-windowed, or differently-composed eval populations as if they measured the same thing.

**[Copy-paste ready version](../../install/evaluate-on-the-same-population.md)** — just the instruction block, no explanation.

## The Problem

Run one: evaluate on all of Q1, after dropping rows with missing features. Run two: evaluate on March, with the new imputation keeping those rows. The metric went from 0.81 to 0.85, and the assistant reports a four-point gain. But the population changed underneath the metric — different time window, different missing-data policy, maybe a new upstream filter that quietly excludes trial accounts now. The four points might be entirely composition: the second population could be easier. Nobody compared models; two different exams got graded and the difference in difficulty was attributed to the student.

This is Simpson's-paradox territory and it cuts both ways: a genuinely better model can look worse because its eval window caught a holiday spike, and a worse one can look better because `dropna` removed the hard rows. Eval populations drift through completely innocent edits — a changed join, a tightened date filter, a schema change that nulls a column the eval filters on — and the metric pipeline reports a clean scalar either way, with nothing attached saying *of what*.

Assistants compound it because they regenerate eval queries fresh each session, reproduce the filters approximately from context, and treat any two numbers with the same metric name as comparable.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Evaluate on the Same Population

Two metrics are comparable ONLY if computed on the same population: same rows, same filters, same time window, same exclusions. Before reporting any metric delta, verify the populations match — otherwise you're reporting a composition change as a model change.

- Define the eval population once, in code, in one place: a shared query or builder function with pinned filters and date ranges that every evaluation calls. Two hand-written "equivalent" filters will diverge.
- Attach population fingerprints to every metric: row count, date range, class balance, and key segment proportions. Report them together — `AUC 0.85 (n=48,112, 2026-03-01..03-31, 7.2% positive)` — so a population shift is visible next to the number it explains.
- Before claiming a delta between two runs, diff their fingerprints first. If n, window, or class balance moved materially, reconcile populations (re-run both on the intersection or on the canonical definition) before comparing scores.
- Watch the quiet population editors: `dropna` policies, inner joins that shed unmatched rows, "active users only" filters with changing definitions, dedup steps, and upstream schema changes that alter what a filter matches.
- When the population legitimately must change (new market, new date range), present it as a new baseline, not a continuation: trend lines must break, not bend, at population redefinitions.
- For segment-level claims, compare segment-to-segment on matched definitions; aggregate metrics over shifting mixes invite Simpson's reversals.

**Red flags that you're about to violate this:**

- "Same metric, same model family — the numbers are comparable..."
- "I'll rewrite the eval filter, it was something like active users in Q1..."
- "The new run drops unparseable rows but that's a tiny difference..."
- "n changed from 48k to 31k, but the metric is a ratio so it's fine..."
- "We improved 4 points (also we changed the date window)..."

---

## Why It Works

1. **A single canonical population definition removes the divergence channel.** Most population drift comes from re-implementing "the same" filter; when every eval imports one definition, sameness is enforced by code rather than asserted by memory.

2. **Fingerprints make composition changes legible at the moment of comparison.** A delta presented next to "n dropped 35%, positives went 7.2%→4.1%" gets the right diagnosis instantly; a bare scalar delta gets a celebration.

3. **Diff-populations-before-diff-scores ordering blocks the false attribution** — the comparison physically can't be reported until the thing that invalidates it has been looked at.

4. **Breaking trend lines at redefinitions protects the historical record.** A bent-but-continuous chart launders a population change into apparent model history; a break forces every future reader to see the discontinuity.

## Origin

A fraud team reported steady quarter-over-quarter precision gains for a year. An auditor preparing a model-risk review noticed eval row counts had fallen 40% over the same period: a "data quality" filter added early in the year excluded transactions from legacy terminals — precisely where fraud was hardest to catch. On the original population, precision had been flat the entire time. The improvement was the eval set politely excusing the model from the difficult questions, one innocent filter at a time.
