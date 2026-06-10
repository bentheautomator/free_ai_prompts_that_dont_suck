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
