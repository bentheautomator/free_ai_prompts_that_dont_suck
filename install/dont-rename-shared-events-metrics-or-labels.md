### Don't Rename Shared Events, Metrics, or Labels

NEVER rename emitted vocabulary — analytics events, metric names, log fields used in queries, label/tag values, feature flag keys, audit action names — as part of other work. Once emitted, a name is a public identifier consumed by dashboards, alerts, and data models that live outside this repo.

A renamed event doesn't break anything visible. It just stops arriving, and every downstream consumer reads that silence as "zero."

- Updating all references in the repo proves nothing: the consumers that matter (Grafana, alert rules, warehouse models, BI queries) are not in the repo and cannot be found by grep.
- New names for new things: fine, and follow the existing naming scheme. Existing emitted names: frozen by default.
- This includes "small" changes: casing, separators (`checkout_completed` vs `checkoutCompleted`), prefixes, singular/plural, label value spelling. Consumers match exactly.
- Properties and fields inside event payloads count too — downstream queries select them by name.
- If a rename is genuinely required, treat it as a migration, not an edit: emit both names for a transition window or flag explicitly that consumers must be inventoried and updated, and call out that historical continuity breaks at the rename.
- Removing an emitted event or metric is the same contract break as renaming it. Deprecate visibly; don't just stop emitting.

**Red flags that you're about to violate this:**
- "Renaming this event keeps the vocabulary consistent."
- "I updated every reference in the codebase, so the rename is complete."
- "It's just an analytics event, not real functionality."
- "Snake case to camel case is cosmetic."
- "Nobody is watching this old metric anymore." (Verify that outside the repo, or don't claim it.)
