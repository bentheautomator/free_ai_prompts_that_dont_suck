---
title: Treat Great Metrics as Bug Signals
slug: treat-great-metrics-as-bug-signals
category: data-and-ml
tags: [universal, ml, evaluation]
works_with: all
severity: high
one_liner: "A 0.99 AUC is a leak detector firing, not a finish line"
---

# Treat Great Metrics as Bug Signals

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents a suspiciously good evaluation score from being celebrated and shipped instead of investigated as probable leakage or a broken eval.

**[Copy-paste ready version](../../install/treat-great-metrics-as-bug-signals.md)** — just the instruction block, no explanation.

## The Problem

When a model jumps from 0.74 to 0.97 AUC after adding one feature, an AI assistant says "great improvement!" and starts writing the summary. It has no prior about what scores are plausible for the problem, so it treats every increase as progress. But on real problems with real noise — churn, fraud, demand, clicks — near-perfect scores are almost never earned. They're the signature of a leak: a feature derived from the label, an eval row that appeared in training, an ID column that memorizes the answer, a "days_until_cancellation" field that is the target wearing a fake mustache.

The asymmetry is brutal. A bug that makes metrics worse gets found immediately, because bad numbers trigger debugging. A bug that makes metrics better triggers a celebration and a deploy, and gets found in production weeks later by people who trusted the offline number. The error survives precisely because it's pleasant.

Assistants amplify this failure because they're trained toward agreeable, success-shaped responses, and a high metric is the most success-shaped artifact in ML. Skepticism toward good news has to be installed explicitly; it does not emerge from wanting to be helpful.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Treat Great Metrics as Bug Signals

When a metric is much better than expected, your FIRST hypothesis is a bug, not a breakthrough. Investigate before celebrating, summarizing, or building anything on top of the number.

- Establish what "expected" is: a trivial baseline (majority class, mean predictor, last-value) and, where possible, prior results on the same problem. A model far above that band needs an explanation, not applause.
- Sudden large jumps from a single change are the strongest signal. Diff exactly what changed and inspect the new feature's relationship to the target before accepting the number.
- Run the standard leak checks: feature/target correlations near 1.0; per-feature ablation (a metric that collapses when one feature is removed says that feature contains the answer); overlap between train and eval rows (`pd.merge` on key columns, or hash-based dedup); features whose values could not have been known at prediction time; ID-like or high-cardinality columns the model may be memorizing.
- Check the eval itself: is the metric computed on the right rows, with labels aligned, against the right baseline class balance? A 0.99 accuracy on 99%-negative data is the baseline, not a model.
- Until the investigation lands, describe the result as "suspiciously high, investigating" in any summary — never as an improvement. Reporting it as a win creates pressure to keep it.
- If investigation finds nothing, say what was checked, then trust the number tentatively. Skepticism is a step, not a permanent state.

**Red flags that you're about to violate this:**

- "0.98 AUC — this feature is incredibly predictive!"
- "The user will be happy with this result, let me write it up..."
- "I don't have a baseline, but higher is better..."
- "The jump is big but the code looks correct..."
- "Validating further would just delay the good news..."
- "It's probably fine; the split happens before training..."

---

## Why It Works

1. **It exploits the error asymmetry directly.** Pessimistic bugs self-report through bad numbers; optimistic bugs only get caught if someone treats good numbers as evidence to audit — this rule makes that audit the default response.

2. **A baseline turns "good" into a checkable claim.** Without a trivial-model reference the assistant has no anchor for plausible; with one, "0.97 on a problem where last-value gets 0.71" is visibly anomalous.

3. **Ablation localizes leaks mechanically.** A metric that craters when one feature is dropped converts a vague suspicion into a specific column to inspect — the fastest path from "weird" to "found it."

4. **Withholding the word "improvement" prevents commitment.** Once a number has been announced as a win, every incentive points toward defending it; "suspicious, investigating" keeps the retraction free.

## Origin

A churn model hit 0.99 AUC after a feature backfill, and the notebook's summary cell cheerfully recommended deployment. The backfilled feature was account status pulled from the current production table — which encodes who eventually churned, the label delivered from the future. One ablation run would have shown the model was 0.99 with the feature and 0.72 without. Instead the gap was discovered after deployment, when live performance came in at exactly the 0.72 the honest features supported.
