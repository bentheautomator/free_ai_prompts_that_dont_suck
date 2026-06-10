---
title: No Features From the Future
slug: no-features-from-the-future
category: data-and-ml
tags: [universal, ml]
works_with: all
severity: critical
one_liner: "Features must use only data available at prediction time, not after the label"
---

# No Features From the Future

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents target leakage from features computed over time windows or table states that include information from after the prediction moment.

**[Copy-paste ready version](../../install/no-features-from-the-future.md)** — just the instruction block, no explanation.

## The Problem

Ask an assistant to build features for "predict churn in the next 30 days" and it will happily compute `total_logins = events.groupby('user_id').size()` — over all events, including the ones that happened after the churn did. Or it joins user attributes from the current state of the users table, where `plan_status` already says "cancelled." Or it aggregates "average order value" across the customer's lifetime, half of which postdates the label window. Each feature is mechanically valid SQL/pandas and conceptually a time machine: the model gets to consult data that won't exist when the prediction actually has to be made.

The result is a model that looks brilliant offline and is useless in production. Offline, every row's features quietly encode its outcome; in production, the future hasn't happened yet, so the signal evaporates. This is the leak that survives a perfectly correct train/test split — the split can be flawless and the features still cheat, because the cheating happened upstream of any split, inside the feature query.

Assistants default to it because tables don't carry timestamps on their truth. A `users` table looks like facts, not facts-as-of-now; an aggregation over all rows is the natural query; and nothing about `groupby().agg()` warns that "all rows" includes tomorrow.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

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

---

## Why It Works

1. **The `as_of` column makes time a first-class constraint.** Once every row carries its prediction moment, "filter to before as_of" is a mechanical rule that can be applied and reviewed per-feature, instead of a vibe about which columns feel safe.

2. **It names current-state joins as the dominant leak vector.** State tables are leakage in its most camouflaged form — they look like attributes, not outcomes — and the rule blocks them categorically rather than asking the assistant to spot the dangerous columns.

3. **It decouples feature hygiene from split hygiene.** Assistants that learn "split by time" believe they've handled temporal leakage; stating explicitly that the split can't absolve the features closes that false-comfort loophole.

4. **The per-feature question ("what would this have been at prediction time?") is answerable**, which makes audits converge — every feature is either provably as-of-safe or flagged.

## Origin

A subscription business built a churn model whose star feature was `support_tickets_count`, joined from the live tickets table. Churning customers file tickets on their way out — after the behavior the model was supposed to predict — so offline AUC was stellar and the deployed model was barely better than tenure alone. The team had split by time, correctly, and cited that as proof there was no leakage; the leak was never in the split. It was in a join that handed every training row a count from its own future.
