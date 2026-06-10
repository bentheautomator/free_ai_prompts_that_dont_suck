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
