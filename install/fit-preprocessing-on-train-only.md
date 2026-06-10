### Fit Preprocessing on Train Data Only

NEVER fit any preprocessing step on data that includes the test or validation set. Split first; fit on train; transform everything else with the already-fitted object. Statistics computed on the full dataset (means, medians, vocabularies, category mappings, feature selections) leak test-set information into training and inflate every metric you report afterward.

- Wrong: `X = scaler.fit_transform(X)` then `train_test_split(X, y)`. Right: split first, then `scaler.fit_transform(X_train)` and `scaler.transform(X_test)`.
- This applies to every fitted step, not just scalers: imputers (`SimpleImputer`), encoders (`OneHotEncoder`, `LabelEncoder`, target encoders), text vectorizers (vocabulary and IDF weights), PCA, feature selection by correlation or importance, outlier-clipping thresholds.
- Prefer an `sklearn.Pipeline` (or equivalent) containing all preprocessing, fit inside `cross_val_score`/`GridSearchCV`, so each CV fold refits preprocessing on its own training portion. Preprocessing done before cross-validation leaks into every fold.
- Target encoding and any feature that aggregates the label are the highest-risk versions; compute them per-fold or with out-of-fold estimates, never globally.
- If preprocessing genuinely needs only constants (e.g., a fixed unit conversion, a hand-specified category list), say so explicitly in a comment; otherwise assume it is fitted and belongs after the split.
- When reviewing existing code, trace every `.fit` and `.fit_transform` call and confirm its input excludes test rows before trusting any reported metric.

**Red flags that you're about to violate this:**

- "I'll normalize the whole dataset first so train and test are on the same scale..."
- "It's just a scaler, the mean barely changes with or without the test rows..."
- "Fitting twice is redundant, fit_transform on everything is cleaner..."
- "I'll do feature selection up front, then split..."
- "Cross-validation will catch any leakage anyway..."
