---
title: Don't Rename Shared Events, Metrics, or Labels
slug: dont-rename-shared-events-metrics-or-labels
category: collaboration
tags: [universal, teamwork, observability]
works_with: all
severity: high
one_liner: "Stops renames of events and metrics that downstream dashboards depend on"
---

# Don't Rename Shared Events, Metrics, or Labels

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from renaming events, metrics, labels, and other shared vocabulary that dashboards, alerts, and analytics downstream depend on.

**[Copy-paste ready version](../../install/dont-rename-shared-events-metrics-or-labels.md)** — just the instruction block, no explanation.

## The Problem

A codebase emits a vocabulary: analytics events (`checkout_completed`), metric names (`payment.latency.p99`), label and tag values (`env:prod`, `tier:critical`), feature flag keys, audit log action names. The code is where these words are born, but their consumers live elsewhere — Grafana dashboards, alert rules, BI queries, data warehouse models, marketing funnels, another team's anomaly detection. The AI, seeing an inconsistent or unfortunate name in the code, renames it: `checkout_completed` becomes `order_completed` for consistency with the new domain language, a metric gets a tidier prefix, a label value gets normalized.

From the repo, the rename looks complete — every reference updated, all tests green. But the repo only contains the producer. Downstream, the dashboard flatlines to zero, the alert that watched the old metric goes permanently quiet, the funnel analysis silently loses its conversion step, and the data team's models join against an event name that stopped arriving. None of it errors. A renamed event doesn't break consumers; it just stops appearing to them, and absence reads as "nothing happened" — which is sometimes exactly what someone is paid to notice, and now can't. Historical continuity dies too: even after consumers update, every chart has a cliff where the old name ends and the new one begins.

The AI does it because, inside the codebase, these are just strings, and improving names is what good refactoring looks like. The dashboards aren't in the repo. The repo is the wrong place to judge whether a name is safe to change.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

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

---

## Why It Works

1. **It corrects the visibility model**: the repo contains only producers, so "all references updated" is structurally false confidence — the rule makes consumed-elsewhere the default assumption.
2. **It names the silence failure**: renames don't error, they zero out, and zeroes are exactly what monitoring and analytics exist to interpret — so the break impersonates the signal.
3. **It freezes emitted names while leaving new names free**, putting the cost only where contracts already exist.
4. **It supplies the migration shape** (dual-emit, consumer inventory, continuity warning) so necessary renames have a path that isn't unilateral breakage.

## Origin

During a domain-language cleanup, an assistant renamed `subscription_cancelled` to `subscription_canceled` — one letter, matching the codebase's American spelling convention. The product analytics funnel, the churn dashboard, and a retention alert all matched the old spelling. Churn reporting read zero cancellations for nineteen days, which leadership initially celebrated. The data team eventually traced the miracle to a one-character commit, backfilled what they could, and now maintains a list of frozen event names — with the British spelling preserved forever as a monument.
