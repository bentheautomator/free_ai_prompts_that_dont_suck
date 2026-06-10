---
title: Never Introduce N+1 Queries
slug: never-introduce-n-plus-one-queries
category: performance
tags: [universal, performance, queries]
works_with: all
severity: critical
one_liner: "Stops loops that fire one database query per row instead of one query total"
---

# Never Introduce N+1 Queries

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from writing loops that issue a separate database query for every item, turning one round trip into thousands.

**[Copy-paste ready version](../../install/never-introduce-n-plus-one-queries.md)** — just the instruction block, no explanation.

## The Problem

The pattern is always the same: fetch a list, then loop over it touching a relation. `for order in orders: print(order.customer.name)`. In an ORM with lazy loading, each `.customer` access is a fresh query. One hundred orders means one hundred and one queries. The code reads beautifully — that's the trap. The ORM made the query invisible, so the AI writes what looks like an in-memory property access and ships a database flood.

AI assistants generate this constantly because it's the dominant pattern in training data and in tutorials, and because nothing in the source code signals a problem. It also passes every test: with ten fixture rows, 11 queries complete in milliseconds. Production has fifty thousand rows. The endpoint that took 80ms in staging takes 90 seconds live, saturates the connection pool, and takes neighboring endpoints down with it.

The same shape appears without an ORM too: a query inside a `for` loop, a `findById` call per element of a mapped array, a `SELECT` per iteration of a report builder. Anywhere the number of queries scales with the number of rows, you've built a time bomb keyed to data growth.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Introduce N+1 Queries

NEVER write code where the number of database queries scales with the number of rows processed. A query inside a loop — explicit or hidden behind an ORM relation — is an N+1 and must be restructured before it ships.

- Accessing a lazy-loaded relation inside a loop is a query per iteration. Use the ORM's eager loading (`select_related`/`prefetch_related`, `includes`, `JOIN FETCH`, `.Include()`, dataloader) on the original fetch instead.
- Replace per-item lookups with one batched query: collect the IDs, fetch with `WHERE id IN (...)`, and join in memory via a map. Same rule for `findById` in a `.map()` and for queries inside list comprehensions.
- Audit the loop body and everything it calls for hidden queries — serializers, `__str__`/`toString` methods, computed properties, and template rendering are classic offenders.
- Verify by counting queries, not by reading code: enable query logging or use the test framework's query counter, run the code path, and confirm the count is constant regardless of row count. With 10 rows and with 200 rows, the number of queries should be identical.
- Tests pass with small fixtures, so passing tests prove nothing here. The query count is the test.

**Red flags that you're about to violate this:**
- "The ORM handles relations efficiently, that's its job."
- "It's just an attribute access, not a query."
- "This list will never be large."
- "It works fine when I run it." (against ten rows)
- "Eager loading makes the code more complicated than it needs to be."

---

## Why It Works

1. **It makes the invisible query visible.** The AI's failure is treating `.customer` as memory access; explicitly naming relation access in a loop as "a query per iteration" rewires the pattern-match.
2. **It demands a count, not a code review.** "Query count must be constant as rows grow" is checkable with a logger and removes all judgment from verification.
3. **It pre-empts the small-fixture alibi.** Stating that passing tests prove nothing closes the loophole the AI uses to declare the code fine.
4. **It covers the hideouts.** Serializers and string methods are where N+1s survive audits; listing them turns a vague rule into a checklist.

## Origin

An assistant added a "recent activity" panel to a dashboard: fetch the 50 latest events, then resolve each event's actor and target through ORM relations in the template. That's 101 queries per page load, invisible in code review. At launch traffic the connection pool drained in minutes and every service sharing that database started timing out. The fix was two `prefetch_related` calls — about 40 characters — found only after a very public incident retro.
