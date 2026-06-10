---
title: Keep Log Lines Stable During Refactors
slug: keep-log-lines-stable-during-refactors
category: refactoring
tags: [universal, refactoring, observability]
works_with: all
severity: high
one_liner: "Stops refactors from rewording logs and metrics that alerting parses"
---

# Keep Log Lines Stable During Refactors

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from rewording log messages, renaming metrics, or restructuring log fields that monitoring, alerting, and dashboards depend on.

**[Copy-paste ready version](../../install/keep-log-lines-stable-during-refactors.md)** — just the instruction block, no explanation.

## The Problem

Log statements look like the most harmless text in a codebase, which is why refactors rewrite them freely. The assistant restructures a function and, in passing, "improves" `log.error("payment declined for order %s", oid)` into `log.error(f"Payment was declined (order: {oid})")`. Better grammar, same information, and the alert that fires on the substring `payment declined for order` goes silent forever. The same applies with higher stakes to metric names (`payments.declined.count` renamed to `payment_declines_total` orphans every dashboard and threshold built on the old name), structured-log field keys (`order_id` becoming `orderId` breaks saved queries), and log levels (an `error` demoted to `warning` slips under the paging rule).

Observability is an API whose consumers live entirely outside the repo: alert definitions, dashboard queries, log-based metrics, SIEM rules, support runbooks that say "search for this phrase." The model sees none of them, so log text registers as prose it's free to polish. The failure is doubly cruel because it disables the very alarms that would have reported it: the system breaks, and the silence reads as health.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Keep Log Lines Stable During Refactors

Treat log messages, log levels, structured-log field names, and metric names as a public API during refactoring. NEVER reword, rename, demote, or restructure them in passing. Alerts, dashboards, saved queries, and runbooks match on these exact strings from outside the repo.

A broken alert fails silently, by definition: the symptom of this mistake is the absence of symptoms.

- Keep log message text byte-stable, especially the constant prefix portion that pattern-matching alerts key on. Grammar improvements are not worth a dead pager rule.
- Keep log levels exactly: error stays error, warning stays warning. Levels route to paging policies; a demotion is an unsubscription from incident response.
- Keep structured-log field keys identical (`order_id`, `duration_ms`, `tenant`); saved queries and log-based metrics aggregate on them. Adding new fields is safe; renaming or removing existing ones is not.
- Metric names, label names, and label values are the strictest contract of all: dashboards, SLOs, and alert thresholds reference them by exact string. Never rename a counter "to follow naming conventions" during cleanup.
- When restructuring moves code, make sure its log statements still execute under the same conditions and the same number of times. A log line hoisted out of a retry loop now undercounts; one moved into a loop floods.
- When deleting code, list any log lines and metrics that die with it, so the user can check for dependent alerts.
- If observability naming genuinely needs improving, propose it as dedicated work with a migration (emit both names temporarily, update consumers, retire the old), never as a refactoring side effect.

**Red flags that you're about to violate this:**

- "I'll make this log message clearer while I'm here."
- "Renaming this metric to match the convention is a trivial fix."
- "This is over-logging; warning is the more appropriate level."
- "It's just a log string; nothing programmatic depends on prose."
- "Switching these logs to structured format is a strict improvement."

---

## Why It Works

1. **It relocates log text from prose to API.** The model's category for log strings is "human-readable commentary, safe to polish"; declaring the consumers (alerts, queries, runbooks) moves the strings into the contract category where its preservation instincts already work.
2. **It names the silent-failure property.** Most regressions announce themselves; this one disables the announcer. Making that explicit raises the perceived stakes above "it's just a string."
3. **The execution-conditions clause catches the indirect breakage.** Even untouched log text breaks monitoring if restructuring changes when or how often it fires; counting frequency and conditions as part of the contract covers the non-textual half.
4. **The dual-emit migration path keeps improvement possible.** Naming conventions do matter eventually; providing the safe sequence (emit both, migrate consumers, retire) means the rule blocks ambushes, not progress.

## Origin

During a logging cleanup bundled into a refactor, an assistant standardized messages and demoted a noisy-looking `error` to `warning`. That error line was the trigger for the on-call page covering failed scheduled payouts. Payouts then failed for three consecutive nights with nobody paged; the team learned about it from customer emails, and the postmortem's root cause read "alert string no longer exists," which is a sentence nobody enjoys writing.
