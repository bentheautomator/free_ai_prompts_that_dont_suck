### Compare Models on the Same Holdout

NEVER claim model B improves on model A unless both were evaluated on the same frozen held-out set, with the same metric implementation, in the same run or from artifacts you can verify match. A comparison across different eval data measures the data difference, not the model difference.

- Freeze a holdout once (fixed rows, saved to disk or pinned by seed and data version) and score every candidate on it. Tuning happens on a separate validation set; the holdout is touched only for final comparisons.
- If the old model's score came from a different split, a different date, or a different notebook, it is not a baseline. Re-score the old model on the current holdout — actually run it — before claiming a delta.
- Same metric, same code path: both models' predictions go through one evaluation function. Two implementations of "F1" (different averaging, different thresholds) can differ by more than your improvement.
- Eval rows must get identical treatment on both sides except the model: same preprocessing version, same filtering. If the new pipeline also changed cleaning, you're comparing pipelines, not models — say so, or isolate the change.
- Report the paired result: both scores, the delta, n, and ideally per-segment or per-fold deltas. A delta smaller than run-to-run seed variance (measure it) is "no detectable difference," not a win.
- No held-out comparison available? Then the honest claim is "not yet compared" — never infer improvement from training loss, vibes, or sample outputs.

**Red flags that you're about to violate this:**

- "The old model got about 0.81 last quarter, and we're at 0.83 now..."
- "Re-running the baseline is a hassle; the logged number is fine..."
- "It's the same dataset, just a fresh random split..."
- "Training loss is lower, so the model is better..."
- "I tuned on this set, but it's still held-out-ish..."
- "The 0.4-point gain is small but it's progress..."
