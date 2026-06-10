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
