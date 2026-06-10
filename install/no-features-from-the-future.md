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
