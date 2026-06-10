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
