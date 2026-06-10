### Don't Slurp Huge Files to Change One Line

ALWAYS check a file's size before reading it whole. Past a few megabytes, switch from load-everything to stream-or-sample.

Whole-file reads scale with the file; the task usually doesn't. A one-line change to a 4 GB file should cost roughly one line of I/O and memory, not 4 GB.

- Check first: `ls -lh <path>` or `du -h <path>`. Make size a fact, not a surprise.
- To inspect: `head`, `tail`, `wc -l` for shape; `grep -n <pattern>` to locate; `sed -n '100,140p'` to view a region. Never cat a large file into your context to "look around."
- To edit: `sed -i 's/old/new/'` for line-level changes; `awk` for columnar work; for structured big data, streaming parsers (`jq -c` over JSONL, `csv` readers row-by-row), not `json.load` on a 2 GB file.
- In code you write, default to iteration for unbounded inputs: `for line in f:` (Python), `readline`/streams (Node), `bufio.Scanner` (Go, mind the token limit). Reserve `read()`/`readFileSync` for files you know are small — configs, source files.
- Logs, dumps, exports, fixtures with `data` in the path, and anything user-uploaded are unbounded until proven otherwise.
- If the task truly needs full-file processing (sorting, global dedup), say so and use disk-backed tools (`sort`, `split`) rather than RAM.

**Red flags that you're about to violate this:**

- "I'll read the file and see what's in it." (How big is it?)
- "json.load is the normal way to read JSON."
- "It worked on the test file." (The test file was 2 KB; production is 2 GB.)
- "I need the whole file to change line 30,000." (sed disagrees.)
- "Memory is cheap." (Not at 3 a.m. when the box is swapping.)
