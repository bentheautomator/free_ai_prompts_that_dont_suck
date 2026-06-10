---
title: SQL Implicit Casts Kill Indexes
slug: sql-implicit-casts-kill-indexes
category: language-pitfalls
tags: [universal, sql]
works_with: all
severity: high
one_liner: "Stops type-mismatched WHERE clauses from forcing silent full table scans"
---

# SQL Implicit Casts Kill Indexes

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents `WHERE phone = 5551234567` against a VARCHAR column from scanning every row — correct results, catastrophic plan, and sometimes wrong results too.

**[Copy-paste ready version](../../install/sql-implicit-casts-kill-indexes.md)** — just the instruction block, no explanation.

## The Problem

Compare a column to a literal of a different type and the database doesn't complain — it inserts a cast. The direction of that cast decides your fate. `WHERE phone_number = 5551234567` against a VARCHAR column makes MySQL cast *the column* to a number for every row: the index on `phone_number` is unusable, the query becomes a full table scan, and as a bonus, string-to-number casting means `'5551234567abc'` equals `5551234567` (and in older modes, weird strings cast to 0 and match a literal 0). PostgreSQL often fails loudly on such mismatches — the lucky outcome — but quietly degrades on others, like comparing a `timestamp` column to a date string in a way that wraps the column in a function.

The same plan-killer appears when the cast is self-inflicted: `WHERE UPPER(email) = ?` or `WHERE DATE(created_at) = '2026-06-01'` wraps the indexed column in a function, which disqualifies the plain index just as thoroughly. Everything still *works* in development, where the table has 200 rows and every plan is fast.

Assistants generate type-mismatched predicates because they infer literal types from how the value looks (digits means number) rather than from the schema, and because application code upstream often holds the value as the wrong type already. The bug ships easily: results are usually correct, so nothing fails until the table is big enough for the scan to hurt.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### SQL Implicit Casts Kill Indexes

ALWAYS match the literal/parameter type to the column type in SQL predicates and joins. A type mismatch makes the database cast — often casting the *column*, which disables its index and can change matching semantics, all without any error.

- Check the schema before writing the predicate. VARCHAR column means quoted string: `WHERE phone = '5551234567'`, never `WHERE phone = 5551234567` (numeric literal forces a per-row cast of the column in MySQL: full scan, plus `'...abc'` suffixed strings matching).
- Numeric column means numeric parameter: passing `'42'` as a string usually casts the parameter (harmless), but dialect rules vary — don't rely on getting the lucky direction. Bind parameters with the correct type in application code rather than leaning on coercion.
- Never wrap an indexed column in a function or cast in WHERE/JOIN: `WHERE DATE(created_at) = ?`, `UPPER(email) = ?`, `CAST(id AS CHAR) = ?` all disqualify the plain index. Restructure to range predicates (`created_at >= '2026-06-01' AND created_at < '2026-06-02'`), store/compare normalized values, or create the matching functional index deliberately.
- Joins across tables: joining a VARCHAR key to an INT key (or mismatched collations/charsets in MySQL) silently de-indexes the join. Fix the schema or cast the side that isn't indexed for the lookup.
- Verify with the planner, not vibes: `EXPLAIN` the query and look for full scans and cast/collation notes on what should be an index lookup.
- When a query is mysteriously slow but correct, type mismatch is one of the first three suspects. Check it before adding an index that already exists.

**Red flags that you're about to violate this:**

- "The value is numeric, so I'll write it without quotes."
- "The database will cast it; same result either way."
- "The query returns the right rows, it's correct."
- "It's fast in my testing." (On the 200-row dev table.)
- "I'll just wrap the column in DATE() to compare days, it reads cleanly."
- "The ORM handles parameter types for me." (Until a raw fragment or a string-typed variable sneaks in.)

---

## Why It Works

1. **It redirects type inference from the literal to the schema.** The model types values by appearance — digits look numeric; making the column's declared type the authority fixes the actual decision procedure that fails.
2. **It links correctness and performance failures to one cause.** Index death and `'...abc'` matching come from the same cast; presenting them together stops the model from treating "results are right" as proof nothing's wrong.
3. **It includes the self-inflicted version.** Function-wrapped columns are the model's favorite "readable" date filter; pairing it with the range-predicate replacement makes the right form as available as the wrong one.
4. **It mandates EXPLAIN as the verification step.** Plans are checkable; "looks fine" isn't. Pointing at the planner converts the rule into something testable in review.

## Origin

A lookup endpoint went from 4ms to 11 seconds as a table grew, and only for one customer segment. The query filtered a VARCHAR external-id column with an unquoted numeric parameter — the ORM had been handed the id as an integer by a single upstream code path. Every request scanned 40 million rows, casting each external id to a number, and threw warnings (nobody read) about truncated casts on ids with letter suffixes. Quoting one parameter restored the index and the on-call's weekend.
