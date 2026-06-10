### Never Evaluate on Training Data

NEVER report a metric computed on rows the model was trained on as the model's performance. Training-set scores measure memorization capacity, not generalization, and for high-capacity models they are near-perfect regardless of whether the model learned anything.

- Wrong: `model.fit(X, y); print(model.score(X, y))`. Right: split first, fit on `X_train`, report `model.score(X_test, y_test)` and label it as held-out.
- Every printed or logged metric must say which split it came from: `train_acc=...`, `test_acc=...`. An unlabeled metric is assumed to be contaminated.
- Training-set metrics are allowed for exactly one purpose: diagnosing under/overfitting by comparing train vs. held-out side by side. Never alone, never as the headline number.
- In notebooks and quick experiments, do the split anyway. "It's just a demo" scores get copy-pasted into real claims.
- If the dataset is too small to hold out a test set, use cross-validation and report the out-of-fold scores — do not fall back to scoring the training rows.
- When summarizing results in comments, docstrings, or commit messages, never carry forward a number without verifying it came from held-out data.

**Red flags that you're about to violate this:**

- "I'll just score it on X and y since they're already in scope..."
- "This is only a sanity check, the real eval comes later..."
- "99% accuracy — the model works, moving on..."
- "Splitting feels like overkill for this small example..."
- "The user just wants to see that training succeeds..."
