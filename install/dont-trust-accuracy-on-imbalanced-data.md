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
