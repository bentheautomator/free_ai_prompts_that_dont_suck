---
title: Process Large Datasets in Pages, Not All at Once
slug: process-large-datasets-in-pages-not-all-at-once
category: backend
tags: [universal, backend, jobs]
works_with: all
severity: high
one_liner: "Keeps batch jobs from loading a whole table into memory and dying"
---

# Process Large Datasets in Pages, Not All at Once

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents batch code that materializes an entire dataset in memory from working at 10,000 rows and OOMing at 10 million.

**[Copy-paste ready version](../../install/process-large-datasets-in-pages-not-all-at-once.md)** — just the instruction block, no explanation.

## The Problem

"Send the monthly report to all users." The assistant writes `users = fetchAllUsers()` and a `for` loop. At dev scale — 50 seeded users — this is correct, fast, and readable. The shape of the code contains a hidden constant: *the entire dataset fits in this process's heap*. Nobody decided that. It's just what `fetchAll` means.

The dataset grows. The job that took seconds takes minutes, then starts consuming gigabytes, then one month it crosses the heap limit and the worker OOMs at the fetch — before processing a single user. Now the monthly report doesn't go out at all, and the only fix under pressure is an emergency rewrite of code that "worked for two years." The pattern hides everywhere: `SELECT *` into an ORM list, `findAll()` results mapped into DTOs (doubling memory), reading a whole CSV/JSON export into an array, collecting all results to count them at the end. ORMs make it worse by hydrating each row into a heavyweight object, so 2GB of table becomes 8GB of objects.

Assistants default to load-then-loop because it's the simplest correct program for the data they can see, and the data they can see is the seed file. Memory ceilings are invisible in every test that doesn't run at production scale — which is every test.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Process Large Datasets in Pages, Not All at Once

NEVER load an unbounded dataset into memory to process it. Any code that reads "all" of anything — all users, all orders, the whole file, the full query result — must work in bounded pages or streams, so memory use is constant no matter how large the dataset grows.

- Iterate with keyset pagination: `WHERE id > :last_id ORDER BY id LIMIT 1000`, carrying the last ID forward. Avoid `OFFSET` for deep pagination — it re-scans skipped rows (O(n²) total) and shifts when rows are inserted or deleted mid-run.
- Use your stack's streaming primitives instead of list-returning calls: server-side cursors (`yield_per`/`iterate` in SQLAlchemy, `stream()` in JPA/Hibernate, `cursor.stream()` in node-pg), `rows.Next()` in Go, generators instead of returned lists.
- For files, read line-by-line or chunk-by-chunk (csv readers, streaming JSON parsers, `bufio.Scanner`) — never `read()` / `readFileSync` on data whose size users control.
- Release per-page memory: clear ORM identity maps/sessions between pages, don't append results to an ever-growing list "to summarize at the end" — keep running aggregates instead.
- Pick a page size deliberately (hundreds to low thousands) and make it configurable; both 10 and 1,000,000 are wrong for different reasons.
- Bound time as well as memory: commit or flush per page so a failure loses one page, not the whole run — pair this with your job-checkpointing rules.
- Apply the same discipline to API consumption: when calling a paginated API, process page-by-page; don't accumulate all pages into one array before starting work.

**Red flags that you're about to violate this:**
- "There are only a few thousand rows."
- "fetchAll keeps the code simple."
- "I'll collect the results into a list and process them after."
- "The server has 16GB, this is fine."
- "It's a one-off script, scale doesn't matter." (One-off scripts run on production tables.)
- "I'll read the file and split on newlines."

---

## Why It Works

1. **It decouples correctness from dataset size.** Load-then-loop is a program whose correctness is a function of row count; paged processing is correct at any count. The rule removes the hidden scale assumption from the code's shape.
2. **It names keyset over OFFSET.** "Paginate" alone yields `OFFSET`-based loops that melt down quadratically on deep tables and skip rows under concurrent writes; specifying the cursor pattern prevents the half-fix.
3. **It targets the accumulation loophole.** Streaming the input and then appending everything to a results array re-creates the original problem one variable later; running aggregates close it.
4. **It bounds blast radius per page.** Page-level commits mean a crash costs one page of rework instead of an all-or-nothing rerun, which compounds with checkpointing into actual operational resilience.

## Origin

A retention team's "email inactive users" script ran fine for two years, starting from 80,000 rows. The user table crossed eleven million; the script's `findAll()` hydrated ORM objects until the worker OOMed roughly forty seconds in, before the first email. It failed silently inside a cron wrapper for three consecutive months — discovered when marketing asked why re-engagement revenue had gone to zero. The rewrite was a keyset loop with a page size of 500 and has run in flat memory ever since.
