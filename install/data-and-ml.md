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

### Avoid Pandas Chained Assignment

NEVER assign through chained indexing in pandas. `df[mask]['col'] = value` writes into a temporary object and may silently change nothing; under copy-on-write (pandas 3.x default) it is guaranteed to change nothing.

- Wrong: `df[df.a > 0]['b'] = 1`. Right: `df.loc[df.a > 0, 'b'] = 1` — one `.loc` with both row and column selection in a single indexing operation.
- Wrong: `sub = df[mask]` then later `sub['col'] = x` while intending to modify `df`. If you need a working subset, take an explicit copy (`sub = df[mask].copy()`) and decide deliberately whether results get merged back; if you mean to edit `df`, use `df.loc[mask, 'col'] = x` directly.
- Never silence `SettingWithCopyWarning` with `pd.set_option('mode.chained_assignment', None)` or warning filters. The warning marks code whose behavior is version- and layout-dependent; fix the indexing instead.
- The same applies through method chains: `df.query('a > 0')['b'] = 1` and `df.dropna()['b'] = 1` assign into temporaries.
- For conditional column updates prefer explicit whole-column constructions: `df['b'] = df['b'].mask(df.a > 0, 1)` or `np.where(...)` — these produce a new column and cannot half-apply.
- After any in-place cleaning step, verify it took: a quick `assert (df.loc[mask, 'col'] == expected).all()` catches a write that landed on a copy.

**Red flags that you're about to violate this:**

- "df[mask]['col'] = value reads cleanly, pandas will figure it out..."
- "It's just a warning, not an error — I'll suppress it..."
- "This exact pattern worked in the last cell..."
- "I'll filter into a variable first, it's the same DataFrame anyway..."
- "No time to restructure the indexing, the assignment probably propagates..."

### Check Join Keys Are Unique

NEVER merge on a key you haven't verified is unique on the side that's supposed to be unique. A duplicate key turns a join into a row multiplier, and every aggregate downstream inherits the inflation silently.

- In pandas, declare the expected relationship on every merge: `orders.merge(customers, on='customer_id', validate='many_to_one')`. It's one argument and it raises the moment the assumption breaks. Use `one_to_one` where that's the contract.
- Where `validate=` isn't available (SQL, Spark), check explicitly before joining: `SELECT key, COUNT(*) FROM dim GROUP BY key HAVING COUNT(*) > 1` or `assert not customers['customer_id'].duplicated().any()`.
- Assert the row count after the join matches intent: a many-to-one enrichment must satisfy `len(result) == len(orders)` (with `how='left'`). Write that assert. Fan-out you wanted should be stated; fan-out you didn't is a bug.
- Watch for NULL keys: rows with null join keys silently drop on inner joins and silently survive on left joins — decide which you want and check `df[key].isna().sum()` first.
- When duplicates are legitimate (history tables, SCD), don't merge raw — resolve to the intended grain first (`drop_duplicates(subset=key, keep='last')` after a deliberate sort, or filter to current records), and say which record wins and why.
- Never "fix" inflated results with a `drop_duplicates()` after the join; that hides the modeling error and keeps an arbitrary row. Fix the grain before joining.

**Red flags that you're about to violate this:**

- "customer_id is obviously unique in the customers table..."
- "The merge ran fine, shapes look reasonable..."
- "I'll dedupe afterward if the numbers look off..."
- "validate= is extra noise on a simple join..."
- "It's a dimension table, dimension tables don't have dupes..."

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

### Don't Cherry-Pick the Best Run

NEVER present the best result from multiple runs, seeds, or metric choices as the result. The maximum of N noisy measurements is an estimate of your luck, not your model. When anything was run more than once or measured more than one way, show the full picture.

- If you ran with multiple seeds or repetitions, give mean and standard deviation (or median and range) across all runs: `f"{np.mean(scores):.3f} ± {np.std(scores):.3f} (n={len(scores)})"`. Never `max(scores)` standing alone.
- If you swept hyperparameters, the score that counts is the chosen config's score on data not used to choose it. Quoting the best validation score as final performance double-dips.
- Decide which metric matters before running, not after seeing the numbers. If you computed five metrics, show all five; do not lead with the flattering one.
- Never discard runs as "warm-up," "flaky," or "looked off" without stating that you did and why. A discarded run is part of the result.
- When comparing against a baseline, both sides get the same number of runs and the same aggregation. Best-of-5 challenger vs single-run baseline is not a comparison.
- State n every time. "0.91" and "0.91, best of 12 attempts" are different claims.

**Red flags that you're about to violate this:**

- "I'll just show the best run, the others had unlucky seeds..."
- "The first two runs were probably warm-up noise, the third is representative..."
- "F1 looks better than accuracy here, I'll lead with F1..."
- "The user wants a single number, a distribution will just confuse things..."
- "This seed clearly worked, no need to mention the sweep..."
- "It hit 0.93 once, so the model is capable of 0.93..."

### Don't Mutate Shared DataFrames in Place

Functions that receive a DataFrame must not modify it. ALWAYS transform a copy and return it; the caller decides what to do with the result. Mutation through a shared reference makes correctness depend on call order, which is invisible in the code.

- Pattern: first line of any transforming function is `df = df.copy()`; transform; `return df`. Caller writes `df = add_features(df)`. The intent is explicit on both sides.
- Avoid `inplace=True` everywhere. It saves no meaningful memory in modern pandas, it returns None (breaking chains and enabling `df = df.dropna(inplace=True)` bugs), and it converts local code into action at a distance.
- Adding or overwriting a column on a parameter (`df['new'] = ...`) is mutation — same rule, even though no `inplace` appears.
- In notebooks, don't write cells that destructively update a shared `df` such that re-running them double-applies (`df['amt'] = np.log(df['amt'])`). Derive new names (`df_feat`) or make the cell idempotent from a stable upstream variable.
- Make transformations re-derivable: prefer one pipeline expression (`df_clean = (raw.pipe(parse).pipe(filter_valid).pipe(add_features))`) over scattered mutations, so the current state of any frame has exactly one definition.
- If you genuinely need in-place behavior for memory at scale, that's an explicit, documented decision with a comment and a name that says so (`mutate_df_inplace_`), never a silent default.

**Red flags that you're about to violate this:**

- "inplace=True is more memory-efficient..."
- ".copy() on every call is wasteful..."
- "This function is the only thing using df right now..."
- "I'll just add the column directly to the argument..."
- "Re-running the cell is fine, the transform is probably idempotent..."

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

### Fail Loudly on Schema Drift

A pipeline that receives data violating its schema must STOP, not adapt. Silent coercion converts an upstream change into downstream garbage; a loud failure converts it into a ticket.

- Validate the schema at the ingestion boundary, explicitly: expected columns, dtypes, and value constraints. Use `pandera`, `pydantic`, Great Expectations, or a plain assert block — but it must exist and it must raise.
- Never use absorbing defaults for structure: no `df.get(col, default)` for required columns, no `if col in df.columns:` guards that quietly skip logic, no `errors='ignore'` on `astype`. A missing or retyped required column is a raise, with a message naming the column and what was expected.
- Validate values, not just types. Unit changes, new enum values, and new sentinel strings (`"N/A"`, `"-"`, `-999`) keep the dtype while changing the meaning — add range checks (`amount.between(0, 1e6)`) and known-categories checks for columns where they're cheap.
- Distinguish additive from breaking drift: a new unexpected column can be a logged warning; a missing, renamed, or retyped expected column is always an error.
- When the user explicitly wants tolerance, quarantine nonconforming rows with counts and samples (see unparseable-row handling) — tolerance means visible triage, never silent coercion.
- On failure, report the diff, not just "validation failed": columns missing, columns unexpected, dtype expected vs received. Make the 3 a.m. page self-explanatory.

**Red flags that you're about to violate this:**

- "I'll make it robust to whatever columns show up..."
- "errors='ignore' keeps the pipeline from being brittle..."
- "If the column's missing I'll just default it to zero..."
- "Strict validation will cause too many failures..."
- "The dtype still matches, the values are probably fine..."
- "We can't have the nightly job crashing over a rename..."

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

### Guard Lossy Type Conversions

NEVER apply a type conversion without accounting for what it destroys. Casts are not plumbing; float→int truncates, datetime→string discards timezone and precision, and numeric parsing of identifiers mutilates them. If a cast can lose information, either prove it doesn't on this data or don't do it.

- Float→int: decide rounding explicitly (`np.round(s).astype(int)` vs truncation) and handle NaN first — `astype(int)` on NaN either raises or, via numpy paths, produces garbage sentinels. If values can be missing, use nullable `Int64`, don't `fillna(0)` your way past it.
- Identifiers are strings, always: ZIP codes, phone numbers, account IDs, EANs. Pin them at read time (`pd.read_csv(..., dtype={'zip': str, 'account_id': str})`) before pandas infers int (losing leading zeros) or float64 (losing precision above 2^53, colliding distinct IDs).
- Datetimes stay datetimes end to end. Persist as Parquet timestamps or ISO-8601 with offset (`s.dt.strftime` is for display only); keep timezone explicit (`tz_localize`/`tz_convert`), and never round-trip through a bare `str()` and re-parse.
- CSV is itself a lossy cast — everything becomes text and dtype inference happens twice. For intermediates, prefer Parquet/Feather, which preserve dtypes; if CSV is required, specify `dtype=` and `parse_dates=` on every read.
- After any unavoidable conversion, assert round-trip fidelity on the data you have: `assert (converted_back == original).all()` or check `s.max() < 2**53` before a float cast of IDs. One assert, run once, beats a quarter of corrupted joins.
- Watch implicit casts too: merging int64 with float64 keys, `concat` upcasting int columns with NaN to float, JSON serialization turning big ints into doubles.

**Red flags that you're about to violate this:**

- "astype(int) will fix this type error..."
- "I'll stringify the timestamps so the CSV writes..."
- "The ID column reads in fine as a number..."
- "fillna(0) then cast, easy..."
- "It's just an intermediate CSV, dtypes will sort themselves out..."
- "The preview looks right, conversion succeeded..."

### Invalidate Stale Intermediate Caches

A cache check must verify validity, not existence. `if path.exists()` is not caching — it's permanently freezing the first run's output. ALWAYS tie cached artifacts to the identity of their inputs.

- Key caches on what they were built from: a hash or fingerprint of input data (file mtimes+sizes at minimum, content hash when feasible) plus the parameters and a version stamp of the producing code. Bake it into the filename (`features_a3f9c2.parquet`) or a sidecar manifest checked before any read.
- Bump the cache key when the producing logic changes: a `CACHE_VERSION = 3` constant included in the key turns "edit the function" into an automatic rebuild instead of a silent stale read.
- Make every cache bypassable: a `--no-cache`/`force_recompute=True` path that's easy to invoke. If the only invalidation procedure is "manually delete a file someone has to know about," the design has failed.
- Log cache decisions: "cache hit: features_a3f9c2.parquet (built 2026-06-02 from raw@d41e)" vs "cache miss: rebuilding." A stale result that announces its birthdate gets caught; a silent one gets trusted.
- Prefer tools that solve this properly when the pipeline justifies it — Make-style dependency tracking, dvc, snakemake, or framework caching keyed on code+data — over hand-rolled `os.path.exists` checks.
- When debugging "my change had no effect," check for caches first, not last. It's the cheapest hypothesis and embarrassingly often the right one.

**Red flags that you're about to violate this:**

- "I'll check if the file exists and skip the slow step..."
- "The raw data basically never changes..."
- "Whoever changes the logic can just delete the cache..."
- "Hashing inputs is overengineering for a notebook..."
- "The output looks the same as before... wait."
- "I'll add a TODO to handle invalidation later..."

### Keep Groups in One Split

Before splitting, identify the entity that makes rows non-independent — user, patient, device, session, document, source image. ALL rows from one entity go to exactly one side. A row-level split on grouped data evaluates memorization and calls it generalization.

- Check for group structure first: does any ID column repeat? `df['user_id'].duplicated().any()`; do rows derive from shared sources (crops of one image, sentences of one document)? If yes, a plain `train_test_split` is wrong by default.
- Split at the group level: `GroupShuffleSplit`, `GroupKFold`, or `StratifiedGroupKFold` with `groups=df['user_id']`; or manually partition unique IDs and filter rows by membership. Never split row indices directly.
- Verify zero overlap after splitting: `assert set(train.user_id) & set(test.user_id) == set()`. One line; run it every time.
- Deduplicate before splitting — exact dupes via hashing, near-dupes where feasible (normalized text, perceptual hashes for images). A duplicated row on both sides is the same leak with no group column to warn you.
- Match the split unit to the deployment question: predicting for new users means split by user; predicting new visits for known users means split visits by time within user — choose deliberately and say which question the metric answers.
- Group splits compose with temporal rules, not replace them: if time matters too, the test groups' data must also come from after training data (see time-based splitting).

**Red flags that you're about to violate this:**

- "Each row is a sample, standard split applies..."
- "Same user appearing in both sides is fine, the sessions are different..."
- "Deduplication can wait until after the baseline..."
- "GroupKFold is more complexity than this project needs..."
- "The model generalizes great — 0.94 on held-out rows..."
- "There's no group column, so there are no groups..." (crops, paragraphs, repeated measurements)

### Keep Labels Aligned With Predictions

NEVER apply a sort, filter, or reorder to features without applying the identical operation, atomically, to labels and any other row-aligned arrays. Alignment is invisible and length checks don't prove it; equal-length misaligned arrays produce confident garbage metrics.

- Keep `X` and `y` in one DataFrame until the last possible moment: sort/filter/dedupe the combined frame, then split with `y = df.pop('target')`. Two variables transformed separately will eventually diverge.
- If they must be separate, derive every subset from one mask: `mask = X.notna().all(axis=1); X, y = X[mask], y[mask]` — never two independently-written conditions that "should" select the same rows.
- Carry a stable row ID through the entire pipeline, and attach it to predictions at scoring time: `preds = pd.DataFrame({'id': ids, 'pred': model.predict(X)})`. Join predictions to labels on ID, never by position, especially across any file write/read boundary.
- `reset_index(drop=True)` discards the only built-in alignment record pandas has. Don't use it to silence alignment warnings; the warning was the diagnosis.
- Beware silent positional alignment: `np.asarray(y)`, `.values`, and most sklearn calls strip the index. Do all row manipulation before converting, and convert `X` and `y` in the same statement or function.
- Before computing any metric, spot-check alignment with a known relationship: join a few predictions back to source rows by ID and confirm the features match what the model saw. One assert on a sentinel row catches a shuffled eval instantly.

**Red flags that you're about to violate this:**

- "I'll sort X by date for the plot, y can stay as is..."
- "Lengths match, so they're aligned..."
- "reset_index(drop=True) will fix this indexing error..."
- "I'll save predictions to CSV and line them up later..."
- "The dropna conditions are basically the same on both..."
- "Positional order survived the merge, surely..."

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

### Never Overwrite Raw Data

NEVER write processed output to the path you read input from. Raw data is the only ground truth; every transformation must produce a new artifact, leaving the source byte-for-byte intact.

- Wrong: `df = pd.read_csv(p); ...; df.to_csv(p)`. Right: read from `data/raw/`, write to `data/processed/` (or a versioned/staged equivalent). Input and output paths must differ, structurally, in every pipeline step.
- Treat `data/raw/` as immutable. Nothing in the codebase writes there except the original ingestion. Enforce it where you can: filesystem permissions (`chmod -R a-w data/raw/`), object-store write protection, or an assert in shared save helpers that refuses paths under the raw root.
- Pipelines must be re-runnable from raw: raw in, derived out, every time. If a step can only run once because it consumes its own input, it's destructive by design — restructure it.
- The same rule applies in memory and in databases: don't mutate the one loaded copy of the source and then persist it; don't `UPDATE`/`DELETE` the ingestion table in place — write cleaned data to a new table or layer.
- If disk space genuinely forbids keeping both, that's a decision for the user, made explicitly with a stated retention plan — never a default you choose silently.
- Filename versioning (`users_v2.csv`) beats overwriting, but directory-stage separation (`raw/` → `interim/` → `processed/`) beats both.

**Red flags that you're about to violate this:**

- "I'll save it back to the same file so there's one source of truth..."
- "Keeping both copies wastes disk..."
- "The cleaning is correct, we won't need the original..."
- "It's simpler if the path doesn't change..."
- "I'll overwrite just this once and re-download if anything goes wrong..."

### Never Silently Drop Unparseable Rows

NEVER let parsing failures remove rows without counting and reporting them. A row that fails to parse is information about your data; making it vanish converts a visible bug into an invisible bias.

- After any coercion step (`errors='coerce'`, `on_bad_lines='skip'`, `try/except` in a row loop), count what was lost and surface it: `n_bad = df['ts'].isna().sum() - n_na_before; log.warning(f"dropped {n_bad}/{len(df)} rows: unparseable ts")`.
- Never write `except Exception: continue` around row parsing. Catch the specific error, increment a counter, and keep a sample of failing rows (e.g., the first 10) for inspection.
- Set a tolerance and enforce it: `assert n_bad / len(df) < 0.01, f"{n_bad} unparseable rows"` — pick the threshold deliberately, don't default to "any amount is fine."
- Check whether failures are concentrated before dropping: group the failing rows by source, date, or region. Parse failures cluster; a cluster means you're about to delete a whole segment, not noise.
- Quarantine, don't delete: write rejected rows to a sidecar file or DataFrame (`rejects.parquet`) so they can be inspected and re-ingested after the parser is fixed.
- `dropna()` with no subset and no comment is a red flag in any loader. Specify columns, state why, and log the row delta.

**Red flags that you're about to violate this:**

- "errors='coerce' and dropna will clean this right up..."
- "It's probably just a few malformed rows, not worth logging..."
- "A bare except keeps the loop simple..."
- "The pipeline needs to not crash, I'll skip bad lines..."
- "Row counts look roughly right, close enough..."
- "We can always reparse later if something seems off..."

### No Features From the Future

Every feature must be computable from information available at the prediction timestamp. NEVER aggregate, join, or look up data from after that moment — features that see the future make the model a fraud that only works offline.

- Give every training row an explicit `as_of` timestamp (the moment the prediction would have been made). Every feature computation filters to data strictly before it: `events[events.ts < row.as_of]`, never `events.groupby(id).agg(...)` over the full table.
- Never join "current state" tables (users, accounts, subscriptions) onto historical training rows. Current state is the future. Use snapshots, slowly-changing-dimension history, or event logs reconstructed as-of the prediction time; if no historical state exists, the feature is unavailable, not approximable by today's value.
- Watch for fields that are updated after the outcome: `status`, `last_login`, `lifetime_value`, `n_support_tickets`, anything `updated_at`-shaped. Ask of each feature: "at prediction time, what would this have been?" If the answer is "different," it's leaking.
- Window definitions must end before the label window begins, with a gap if the label takes time to materialize. "Activity in last 30 days" and "churn in next 30 days" must not overlap by even a day.
- Time-based train/eval separation doesn't fix feature leakage: a perfect split with leaky features still produces a leaky model. Audit features independently of the split.
- In code review, treat any unbounded aggregation in a feature pipeline (`groupby` without a time filter) as a defect until shown otherwise.

**Red flags that you're about to violate this:**

- "I'll join the users table for their attributes..."
- "Total lifetime activity is a strong feature..."
- "The events table is what we have, I'll aggregate all of it..."
- "We don't keep historical snapshots, current values are close enough..."
- "The split is by time, so leakage is already handled..."
- "Validation AUC is 0.96 — these features are great..."

### No Hardcoded Paths in Pipelines

NEVER bake absolute, machine-specific paths into pipeline or notebook code. A path like `/Users/x/Downloads/data.csv` makes the code runnable on exactly one machine and makes it ambiguous which data produced which result.

- Take data locations from configuration: an environment variable (`DATA_DIR = os.environ["DATA_DIR"]`), a CLI argument (`argparse`/`click`), or a config file checked into the repo with per-environment overrides.
- Build paths relative to a defined root, not the current working directory: `DATA_DIR / "raw" / "customers.csv"` using `pathlib.Path`, where `DATA_DIR` comes from config. Avoid `../../data` relative paths — they break the moment the script is invoked from a different directory.
- Never construct paths with `os.path.expanduser("~")` plus a personal directory layout, and never reference `Downloads`, `Desktop`, or a username in a path. Those names are the smell.
- If the user hands you a literal local path, use it once to locate the data, then immediately parameterize: define the variable at the top of the file or read it from the environment, with the user's path as a documented example default at most.
- Fail loudly and helpfully when the location is missing: `raise FileNotFoundError(f"Set DATA_DIR (looked in {path})")` beats a stack trace from deep inside `read_csv`.
- Output paths follow the same rule — results, models, and caches go under a configured output root, never a hardcoded personal folder.

**Red flags that you're about to violate this:**

- "I'll just use the path the user pasted, it works..."
- "It's only a notebook, nobody else will run it..."
- "Parameterizing is overkill for a quick script..."
- "I'll point it at my Downloads folder for now and fix it later..."
- "Everyone on the team probably has the data in the same place..."

### Run Notebooks Top to Bottom

A notebook's results are only valid if produced by a clean, top-to-bottom run. ALWAYS verify with Restart & Run All (or `jupyter nbconvert --execute`, or `papermill`) before treating any notebook output as a result or committing the notebook.

- Cells must be ordered so each one depends only on cells above it. If you find yourself scrolling up to re-run an earlier cell after editing it, reorder the notebook so the dependency reads downward.
- Never depend on state from deleted or edited-away cells. After renaming a variable or function, restart the kernel; the old binding surviving in memory is how `df_clean`-vs-`df` bugs hide.
- Don't redefine the same variable to mean different things in different cells (`df` raw in cell 2, `df` filtered in cell 9). Downstream cells silently bind to whichever ran last. Use distinct names.
- Keep imports, config, and constants in the first cells, not sprinkled where they happened to be needed during exploration.
- Out-of-order execution counts (`[17]` above `[4]`) on a notebook you're about to commit or cite are a stop sign: restart and run all first.
- For anything load-bearing (pipelines, scheduled jobs, shared analyses), move logic into importable `.py` modules and keep the notebook as a thin driver; kernels forget, files don't.

**Red flags that you're about to violate this:**

- "I'll just re-run this one cell, the rest of the state is fine..."
- "Restart & Run All takes ten minutes, the outputs are already there..."
- "I deleted that cell but the variable it made is still good..."
- "df is the filtered version right now, I'll remember that..."
- "The execution counts are out of order but the numbers look right..."

### Seed and Version Every Run

Every experiment must be re-runnable to the same result. ALWAYS pin the three things that vary: randomness, data, and configuration — before trusting or reporting any number.

- Set seeds explicitly everywhere randomness enters: `random_state=SEED` in every `train_test_split`, model constructor, and CV splitter; `np.random.seed(SEED)`; framework seeds (`torch.manual_seed`, `tf.random.set_seed`) where applicable. Define `SEED` once at the top, not scattered literals.
- Seeds are for reproducibility, not performance. Never tune the seed; if results swing meaningfully across seeds, that variance is a finding to report (see multi-run averaging), not a dial to turn.
- Pin the data identity, not just the filename. Record a content hash, snapshot path, or data-version tag (DVC, lakeFS, a dated immutable copy) alongside results. `data.csv` is a name, not a version.
- Record the run's configuration with its result: hyperparameters, code commit, data hash, seed — as a logged dict, a JSON sidecar next to the metrics, or an experiment tracker entry. A metric without its config is unfalsifiable.
- Outputs should never silently overwrite previous outputs: write models and metrics to run-specific paths (`runs/2026-06-10_a1b2c3/`) so history survives.
- Note known nondeterminism you can't remove (GPU atomics, multithreaded data loading) so a small wobble on rerun isn't misread as a code change.

**Red flags that you're about to violate this:**

- "It's a quick experiment, seeding is ceremony..."
- "The split is random but it'll be roughly the same every time..."
- "I'll remember which CSV this was..."
- "I'll add tracking once the model actually works..."
- "The number moved on rerun, but it's probably fine..."
- "Let me try a different seed, that one was unlucky..."

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

### Stream Data Instead of Loading It All

NEVER assume the dataset fits in memory. Before writing whole-dataset code, establish the real data size and the available RAM/VRAM; when full-size data is or will be larger than a comfortable fraction of memory, process it incrementally by design.

- Check size first: file bytes times a 3-8x in-memory multiplier for CSV→DataFrame, `df.memory_usage(deep=True).sum()` on a sample, extrapolated. Code that works only on the dev sample's scale should say so out loud.
- Read incrementally: `pd.read_csv(..., chunksize=100_000)` with per-chunk aggregation, `pyarrow.parquet` with column and row-group selection, or push the heavy lifting to engines built for out-of-core work (Polars lazy/streaming, DuckDB querying files directly, Dask/Spark at cluster scale).
- Load only what you use: `usecols=`/column projection, predicate pushdown via Parquet filters, and proper dtypes (`category` for low-cardinality strings, downcast floats/ints) — often a 5-10x footprint cut before any streaming is needed.
- On GPU, batch by construction: `DataLoader` with a tuned `batch_size`, never `torch.tensor(full_dataset).cuda()`. VRAM holds model + batch + gradients + optimizer state, not the corpus.
- Watch peak memory, not resting memory: merges, `concat`, sorts, and `astype` create temporary copies that can double usage. Aggregate-as-you-go beats build-then-reduce (`pd.concat(list_of_everything)`).
- If you choose full in-memory because the data verifiably fits with headroom, state the size, the limit, and what happens when the data grows — that's a decision; silence is just hope.

**Red flags that you're about to violate this:**

- "read_csv the whole thing, it's simpler..."
- "It loads fine on my sample..."
- "I'll move the entire tensor to GPU so it's fast..."
- "The file is only 15GB and the box has 64..."
- "concat everything first, then aggregate..."
- "We can deal with memory when it becomes a problem..."

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
