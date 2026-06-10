### Split Time Series by Time

If rows have a meaningful time dimension, NEVER split them randomly. Train on the past, evaluate on the future, always — a shuffled split lets the model see ahead of its test set and reports interpolation skill as forecasting skill.

- Wrong: `train_test_split(X, y, test_size=0.2)` on timestamped data. Right: pick a cutoff and split by it — `train = df[df.ts < cutoff]; test = df[df.ts >= cutoff]` — with the test window entirely after the train window.
- For cross-validation, use forward-chaining (`sklearn.model_selection.TimeSeriesSplit` or equivalent expanding/rolling windows), never `KFold`/`cross_val_score` defaults, which shuffle or interleave folds across time.
- Mind the boundary: if labels or features are windowed (e.g., target is "next 7 days"), leave a gap of at least the window length between train end and test start, or boundary rows leak across.
- Before deciding the split, ask whether time matters even if the task isn't "forecasting": user behavior, transactions, logs, and text scraped over time all drift, and a random split overstates performance on all of them. Default to temporal splits whenever a timestamp exists; justify random splits, not the reverse.
- Hyperparameter tuning obeys the same arrow: the validation window must follow the training window, and the final test window must follow both.
- Evaluate against a persistence baseline (predict last known value / same period last cycle). On a shuffled split persistence looks beatable; on an honest split it tells you whether the model does anything at all.

**Red flags that you're about to violate this:**

- "train_test_split with a fixed seed is the standard approach..."
- "It's not really forecasting, so random splitting is fine..."
- "K-fold gives more reliable estimates than a single time split..."
- "Stratifying by month handles the time structure..."
- "The model scores 0.95 — the random split clearly didn't hurt..."
