---
title: Keep Groups in One Split
slug: keep-groups-in-one-split
category: data-and-ml
tags: [universal, ml, evaluation]
works_with: all
severity: high
one_liner: "Same-entity rows in both train and test reward memorizing, not generalizing"
---

# Keep Groups in One Split

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents train/test splits that scatter rows from the same user, patient, session, or document across both sides, turning evaluation into entity recognition.

**[Copy-paste ready version](../../install/keep-groups-in-one-split.md)** — just the instruction block, no explanation.

## The Problem

When each entity contributes multiple rows — a user's many sessions, a patient's repeated scans, a document's many paragraphs, near-duplicate images — a row-level `train_test_split` puts some of each entity's rows in train and the rest in test. The model then meets test rows from entities it memorized during training. It doesn't need to learn the task; it learns the entities. Patient 4471's scans share an anatomy, a user's sessions share habits and device quirks, and the model's "skill" at test time is substantially recognizing whom it's looking at.

Evaluation answers "how well does the model handle new rows from entities it knows?" while deployment asks "how well does it handle entities it's never seen?" — and the gap between those two questions can be enormous. This is the leak that survives every other hygiene measure: preprocessing fitted correctly, labels aligned, no future features, and the eval is still inflated because the partition itself is wrong. Duplicates and near-duplicates are the degenerate case — the literal same example on both sides.

Assistants miss it because group structure isn't visible in `X.shape`. The data looks like independent rows, the standard split is the standard split, and the inflated metric reads as success.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

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

---

## Why It Works

1. **It aligns the eval partition with the deployment boundary.** Production presents unseen entities; only a group-level split makes the test set unseen in the way that matters, so the metric estimates the deployed quantity instead of an upper bound on it.

2. **The duplicated-ID check makes hidden structure visible before it can leak.** Group leakage's camouflage is that rows look independent; one `duplicated().any()` per ID-shaped column strips it.

3. **The overlap assert converts a statistical subtlety into a binary pass/fail** — no judgment required, fails loudly, costs nothing, and catches the regression when someone later "simplifies" the split.

4. **Naming the question ("new users" vs "new visits") prevents the right metric for the wrong deployment** — both splits are valid for different products, and stating which one you ran blocks the silent mismatch.

## Origin

A medical-imaging classifier scored 0.95 AUC with a clean random split over scans — multiple scans per patient, scattered across both sides. Split by patient instead, it fell to 0.78: the model had been recognizing individual anatomy, not pathology. The discrepancy was found during external validation at a second site, after the 0.95 had already headlined a funding deck. The patient-level assert now runs in their CI, where it is one line long and unskippable.
