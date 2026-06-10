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
