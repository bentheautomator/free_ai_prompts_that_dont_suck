---
title: Don't Trust Accuracy on Imbalanced Data
slug: dont-trust-accuracy-on-imbalanced-data
category: data-and-ml
tags: [universal, ml, evaluation]
works_with: all
severity: high
one_liner: "99% accuracy on 99%-negative data describes the class balance, not the model"
---

# Don't Trust Accuracy on Imbalanced Data

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents reporting accuracy on imbalanced classes, where a model that detects nothing scores like a model that works.

**[Copy-paste ready version](../../install/dont-trust-accuracy-on-imbalanced-data.md)** — just the instruction block, no explanation.

## The Problem

Fraud is 0.5% of transactions, the model predicts "not fraud" for everything, and `accuracy_score` returns 0.995. An AI assistant asked to "build a classifier and evaluate it" will reach for accuracy because it's the default, the universal first metric of every tutorial, and the number that comes back is large. The summary writes itself: "the model achieves 99.5% accuracy." The model achieves nothing. It is a constant function with a press release.

The failure compounds in retraining and iteration: when accuracy is the target of comparison, the degenerate all-majority predictor is a strong local optimum, so changes that improve real detection can lower accuracy and get reverted, while changes that collapse the model toward "predict nothing" look neutral or positive. The metric isn't just uninformative — it actively steers development toward the useless model. And class imbalance is not exotic; it's the natural state of fraud, churn, defects, disease, clicks, and alerts. The interesting class is almost always the rare one.

Assistants fall for it because accuracy is what the API hands you, big numbers terminate the task pleasantly, and nothing in `0.995` discloses that the baseline was `0.995`.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Don't Trust Accuracy on Imbalanced Data

ALWAYS check the class balance before choosing a metric, and NEVER report accuracy alone when classes are imbalanced. The first number to compute is the majority-class baseline (`y.value_counts(normalize=True).max()`); any accuracy must be read against it, and an accuracy near it means the model may be doing nothing.

- For imbalanced problems, report per-class behavior: precision, recall, and F1 for the minority class (`classification_report`), plus the confusion matrix. A model is characterized by what it does on the class that matters, not by its agreement rate with the majority.
- Prefer threshold-aware summaries suited to imbalance: precision-recall AUC over ROC AUC when positives are rare (ROC AUC can look healthy while precision is unusable), and report the operating point — at the chosen threshold, what precision and what recall.
- Always include the trivial baselines in the comparison table: predict-all-majority and predict-by-prevalence. The model's job is to beat them visibly; if the report doesn't show them, the reader can't tell whether it did.
- Don't "fix" imbalance silently: resampling (SMOTE, under/oversampling) belongs inside the training fold only — never applied before splitting, and never to the test set, which must keep the real-world distribution the metric claims to describe.
- Check the predicted-class distribution as a smoke test: `pd.Series(preds).value_counts()`. A classifier that never predicts the minority class has told you everything, whatever the accuracy says.
- State prevalence next to every metric: "recall 0.62 at precision 0.40, prevalence 0.5%" is a result; "accuracy 0.995" on the same data is camouflage.

**Red flags that you're about to violate this:**

- "99.5% accuracy — excellent results!"
- "Accuracy is the standard metric, I'll start with that..."
- "The classes are only somewhat imbalanced, accuracy is fine..."
- "ROC AUC is 0.93, no need to look at precision-recall..."
- "I'll oversample the dataset first, then split..."
- "The user asked for accuracy, so accuracy is what I'll report..."

---

## Why It Works

1. **The majority-baseline-first ordering defuses the big number before it can impress.** "0.995 vs a 0.995 baseline" reads as zero, which is the correct reading; without the anchor, the same number reads as success.

2. **Minority-class metrics measure the actual task.** Rare-class problems exist to catch the rare class; precision/recall on it is the quantity the business named, while accuracy is dominated by the class nobody asked about.

3. **The predicted-distribution smoke test catches the degenerate model in one line** — a constant predictor is invisible in accuracy and unmistakable in `value_counts()`.

4. **Confining resampling to the training fold protects the metric's meaning.** A rebalanced test set answers a question about a world that doesn't exist; keeping test prevalence real keeps the reported precision attached to production reality.

## Origin

A defect-detection model for a manufacturing line was reported at 99.2% accuracy and approved for a pilot. On the line, it flagged nothing for three weeks — including a defect batch that reached customers. Defect prevalence was 0.8%; the model was the constant function, and had been since training, where early stopping on validation accuracy had selected it over every variant that actually fired. The confusion matrix that would have shown an empty positive column was never printed.
