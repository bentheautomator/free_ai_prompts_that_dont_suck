---
title: Filter in the Query, Not in App Memory
slug: filter-in-the-query-not-in-app-memory
category: performance
tags: [universal, performance, queries]
works_with: all
severity: critical
one_liner: "Stops fetching entire tables into memory to filter, count, or find one row"
---

# Filter in the Query, Not in App Memory

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from loading a whole dataset into application memory and then filtering, counting, or searching it in a loop the database would have done for free.

**[Copy-paste ready version](../../install/filter-in-the-query-not-in-app-memory.md)** — just the instruction block, no explanation.

## The Problem

`const users = await db.users.findAll(); const user = users.find(u => u.email === email);` — fetch every row, ship it across the network, deserialize it into objects, then scan the array for the one row you wanted. AI assistants write this shape relentlessly: `.filter()` after `findAll`, `len(Model.objects.all())` instead of `.count()`, summing a column by iterating every record, checking existence by loading the table and testing membership.

It happens because the AI thinks in the language it's generating, not in SQL. Array methods are right there, autocomplete-friendly, and identical in shape to the in-memory operations it writes all day. The database's ability to filter, count, aggregate, and index-search is a separate mental model the AI skips when the application-side version typechecks.

The cost curve is brutal. At 1,000 rows nobody notices. At 1,000,000 rows, every call transfers hundreds of megabytes, the app server's heap balloons, GC pauses stack up, and one innocent-looking lookup OOMs the process. Unlike a slow query, this failure takes the whole service down — and it gets worse every day the table grows.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Filter in the Query, Not in App Memory

NEVER fetch a full dataset into application memory to filter, search, count, aggregate, or check existence. Push the predicate into the query; the database does this work with indexes, the application does it by melting.

- Finding one row: `WHERE email = ?` (or the ORM equivalent), never `findAll()` followed by `.find()`/`.filter()`.
- Counting: `COUNT(*)` / `.count()`, never `len(fetch_everything())` or `.length` on a fetched array.
- Aggregating: `SUM`, `MAX`, `GROUP BY` / the ORM's aggregate API, never a loop accumulating over all rows.
- Existence checks: `EXISTS` / `.exists()` / `LIMIT 1`, never load-then-membership-test.
- The same rule applies to external APIs and files: use the API's filter parameters and search endpoints rather than fetching all pages and filtering client-side.
- Loading the full set is acceptable only when the caller genuinely needs (nearly) all rows for processing — and then say so explicitly and confirm the realistic upper bound on row count with the user.
- Before finishing, reread each data access and ask: does the amount of data transferred scale with the table size or with the result size? It must scale with the result.

**Red flags that you're about to violate this:**
- "I'll just fetch them all and filter — simpler than building the query."
- "Array methods are more readable than SQL here."
- "This table is small."
- "I already have a findAll helper, I'll reuse it."
- "It's only called once per request."

---

## Why It Works

1. **It supplies the missing translation table.** The AI fails per-operation (find, count, sum, exists), so the rule maps each in-memory habit to its query-side replacement instead of stating an abstract principle.
2. **It gives a scaling invariant to check.** "Transfer scales with result size, not table size" turns code review into a yes/no question the AI can answer about its own diff.
3. **It closes the 'small table' loophole** by requiring the bound to be stated and confirmed, converting a silent assumption into a visible, challengeable claim.
4. **It extends to APIs and files**, where the identical mistake hides under different syntax and would otherwise survive the rule.

## Origin

A login flow needed to look up a user by email. The assistant generated `findAll()` plus an in-memory `.find()`, and it shipped because the dev database had 200 users. Production had 1.4 million. Every login attempt pulled the entire users table over the wire; at peak hour the API pods OOM-looped and authentication was down for 40 minutes. The corrected version was one indexed `WHERE` clause that ran in under a millisecond.
