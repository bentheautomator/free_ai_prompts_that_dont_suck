---
title: Audit NaNs Before Aggregating
slug: audit-nans-before-aggregating
category: data-and-ml
tags: [universal, data, pandas]
works_with: all
severity: high
one_liner: "Aggregations skip NaNs silently, so your mean describes only the rows that answered"
---

# Audit NaNs Before Aggregating

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents missing values from silently shaping sums, means, and counts that get reported as if computed on the whole dataset.

**[Copy-paste ready version](../../install/audit-nans-before-aggregating.md)** — just the instruction block, no explanation.

## The Problem

Pandas aggregations are polite about missing data to a fault: `df['revenue'].mean()` skips NaNs without a word, `sum()` of an all-NaN group returns 0.0 as if that were a measurement, `count()` quietly counts only non-null entries, and `groupby` drops NaN keys entirely by default. An assistant computing "average revenue per region" gets a clean table of numbers with no indication that one region was 60% missing and another contributed nothing but got dropped from the output. Arithmetic comparisons add their own trap: `df[df.score > 0.5]` silently excludes NaN scores from both this filter and its complement, so the two "halves" don't sum to the whole.

The output is a statistic about respondents presented as a statistic about the population. If missingness were random this would merely widen error bars, but missingness never is — it tracks a broken collector, a region that launched late, a field one client never fills in. The mean moved because the missing rows differ from the present ones, and nothing in the printed table shows it.

Assistants fall into this because skipna behavior makes broken data produce unremarkable numbers. There's no error to react to; the failure mode is a plausible value.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Audit NaNs Before Aggregating

ALWAYS measure missingness before computing aggregates, and report it next to the result. Pandas skips NaNs silently, so every mean, sum, and count is implicitly conditioned on "rows where this happened to be present."

- Before aggregating a column, check the null fraction: `df['revenue'].isna().mean()`. If it's material (pick a threshold; >1-5% usually is), the aggregate must carry it: report `mean` alongside `n` and `pct_missing`, e.g. via `.agg(['mean', 'count', lambda s: s.isna().mean()])`.
- Check whether missingness is concentrated: `df.groupby('region')['revenue'].apply(lambda s: s.isna().mean())`. Uniform missingness widens uncertainty; clustered missingness biases the answer.
- Know the dangerous identities: `sum()` of all-NaN is `0.0` (use `min_count=1` to get NaN instead); `count()` is non-null count, not row count (`size()` is rows); `groupby` drops NaN keys unless `dropna=False`; comparisons like `x > 0.5` are False for NaN, so filters silently shed missing rows.
- Never `fillna(0)` (or any constant) just to make aggregation "work." Zero is a value with meaning; imputation is a modeling decision made explicitly, with the method and the affected fraction stated.
- When filtering on a column with NaNs, decide their fate explicitly: `df[df.score.gt(0.5)]` vs `df[df.score.gt(0.5) | df.score.isna()]` are different populations — say which you mean.
- In reports and notebooks, a number derived from a column with material missingness gets a caveat in the same cell, not in a separate data-quality section nobody reads.

**Red flags that you're about to violate this:**

- "mean() handles NaNs automatically, so this is fine..."
- "I'll fillna(0) so the groupby works..."
- "Missing values are probably rare in this column..."
- "The two filtered halves should cover everything..."
- "The aggregate looks reasonable, the data must be complete..."

---

## Why It Works

1. **It changes what the number claims to be.** "Mean of present values, 38% missing" and "mean revenue" are different statements; forcing n and missing-rate into the output makes the reader evaluate the first claim instead of assuming the second.

2. **The clustering check targets the actual bias mechanism.** Aggregates go wrong when missingness correlates with the grouping variable; one groupby on `isna()` exposes exactly that correlation before it ships.

3. **Knowing the identities defuses the landmines individually.** `sum()=0.0`, `count()` vs `size()`, dropped NaN group keys, and NaN-excluding comparisons each have a one-argument fix — but only for someone who knows to reach for it.

4. **Banning reflexive `fillna(0)` keeps missingness visible** until a human chooses an imputation, instead of laundering "unknown" into "zero" at the first inconvenience.

## Origin

A weekly ops report showed average delivery time improving for six straight weeks — celebrated, until someone noticed the timestamps feeding it. A firmware update had stopped one courier fleet's scanners from reporting delivery events, so the slowest segment of deliveries was simply absent from the mean, in growing proportion. The metric had measured scanner coverage, not delivery speed, and `pct_missing` printed next to the average would have shown it in week one.
