---
title: Never Fetch Everything to Serve One Page
slug: never-fetch-everything-to-serve-one-page
category: performance
tags: [universal, performance, scaling]
works_with: all
severity: high
one_liner: "Stops fetch-all-then-slice pagination that loads every row to show twenty"
---

# Never Fetch Everything to Serve One Page

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from implementing pagination by pulling the entire dataset and slicing it in application code.

**[Copy-paste ready version](../../install/never-fetch-everything-to-serve-one-page.md)** — just the instruction block, no explanation.

## The Problem

Ask for a paginated list endpoint and you'll frequently get this: `const all = await Order.findAll(); return all.slice(offset, offset + 20)`. Or the Python flavor: fetch every row, sort the list in memory, return `items[start:end]`. The page renders twenty items; the server fetched, deserialized, and hydrated two hundred thousand to produce them. Page 2 does it all again. The API response is paginated. The work is not.

AI assistants reach for this because slicing an in-memory list is the universally known operation, while real pagination is per-stack: `LIMIT/OFFSET` or keyset queries in SQL, cursor parameters on REST APIs, continuation tokens on cloud SDKs. Fetch-then-slice also produces a perfectly correct-looking response on a 50-row dev database, so nothing pushes back during development. The same failure hides inside "give me the latest 10" features: fetch all, sort, take ten.

The cost scales with the table, not the page. At 200k rows, every page view is a multi-second full-table transfer, memory spikes per request, and the database does maximal work for minimal output. Users see a fast-looking paginated UI backed by the most expensive query pattern available.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Fetch Everything to Serve One Page

NEVER implement pagination, "top N," or "latest N" by fetching the full dataset and slicing, sorting, or truncating it in application memory. The limit must be applied at the data source, so the bytes transferred scale with the page size, not the table size.

Fetch-then-slice returns the right twenty items while doing the work of all two hundred thousand, on every page view.

- SQL: put `ORDER BY` plus `LIMIT`/`OFFSET` (or better, keyset/seek pagination: `WHERE sort_key > :cursor ORDER BY sort_key LIMIT :n`) in the query itself. "Latest 10" is `ORDER BY created_at DESC LIMIT 10`, never sort-in-app-and-take-ten.
- ORMs: use the query builder's `limit`/`offset`/`take`/`skip` before execution. `.all()` followed by Python/JS slicing means the limit happened too late.
- Upstream APIs: pass their page-size and cursor/continuation parameters through instead of draining all pages to serve one. If the upstream paginates, your wrapper should too.
- Prefer keyset/cursor pagination over large offsets when the dataset is big; `OFFSET 100000` still walks the skipped rows.
- Counts come from `COUNT(*)`, not from `len()` of a fully fetched list.
- Verify by inspecting what actually executed: the query log must show the LIMIT, and the rows-returned count for a page-of-20 request must be about 20. If the data layer returned the whole table, the test fails regardless of what the HTTP response looks like.

**Red flags that you're about to violate this:**
- "Slicing the array is simpler and the result is identical."
- "The table is small right now."
- "I need the full list anyway to compute the total count."
- "Sorting in the app avoids worrying about database collation."
- "The ORM call already ran, easier to paginate what I have."

---

## Why It Works

1. **It relocates the limit by rule.** "The limit must be applied at the data source" is a placement constraint the AI can check syntactically: is `LIMIT`/`take`/page-size in the query or after it?
2. **It separates response shape from work done.** Naming that a paginated response can hide unpaginated work removes the AI's main false signal of success (the API returns 20 items, so it must be fine).
3. **It closes the count loophole.** "I need everything for the total" is the most common justification; prescribing `COUNT(*)` deletes it.
4. **It verifies at the query log.** Rows-returned-per-request is an observable number that small dev datasets can't disguise the way response payloads can.

## Origin

An admin "Recent signups" page was built as fetch-all-users, sort by date in JavaScript, slice the first 25. At launch (300 users) it was instant. Two years later, at 1.4 million users, every load of the admin home pulled the entire user table, took 40 seconds, and occasionally OOM'd the API pod. Support staff had learned to open the page once in the morning and never refresh. Moving the sort and a `LIMIT 25` into the query took the load time to 30 milliseconds.
