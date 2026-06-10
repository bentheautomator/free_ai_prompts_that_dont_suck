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
