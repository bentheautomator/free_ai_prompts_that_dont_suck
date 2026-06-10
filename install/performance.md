### Avoid Catastrophic Regex Backtracking

NEVER apply a regex with nested quantifiers, quantified groups containing quantifiers, or overlapping alternations to user-controlled input. On a backtracking engine these patterns take exponential time on inputs that nearly match, and one crafted string can peg a CPU core for minutes.

The danger shapes, learn them on sight: `(x+)+`, `(x*)*`, `(x+)*`, `(x|xy)+`, `(\s*,\s*)*`, and any group where the same character could be consumed by either of two adjacent quantifiers (`\w+\s?` repeated, `.*.*`).

- Make repetition unambiguous: each character of input should have exactly one way to be consumed. Prefer explicit character classes with single quantifiers (`[\w.+-]+@[\w-]+\.[\w.]+`) over quantified groups of quantified things.
- Anchor patterns and bound repetition where the domain allows (`{1,64}` instead of `+` for an email local part). Bounded repetition caps the search space.
- Length-limit the input before the regex runs. A 100-character cap turns a theoretical exponential into a non-event.
- Where available, prefer a non-backtracking engine for user input: RE2, Rust's `regex`, Go's `regexp`, .NET's `NonBacktracking` flag, or a regex timeout if the platform offers one.
- Often the honest fix is not using a regex: `split`, `startsWith`, or a real parser for emails/URLs (the platform has one).
- Verify with a near-miss test: run the pattern against a long input that almost matches (e.g., 50 repetitions of the repeated unit plus one breaking character) and assert it completes in milliseconds. Matching valid input fast proves nothing; failing fast is the property under test.

**Red flags that you're about to violate this:**
- "This regex passes all the test cases."
- "Nesting the group keeps the pattern readable."
- "Nobody would ever input a string like that."
- "Regex performance is the engine's problem."
- "I'll combine these two patterns into one with an outer `+`."
- "It's just a validation regex, how slow can it be?"

### Batch Per-Item Network Calls

NEVER make a network call (HTTP, RPC, queue publish, cache get/set, cloud SDK operation) inside a loop over a collection without first checking for a batch form of the same operation. Per-item calls pay full round-trip latency and a rate-limit token per element; batch calls pay them once.

- Before writing the loop, search the API for the plural: bulk/batch endpoints, `mget`/`mset`, multi-get, list filters that accept many IDs (`?ids=1,2,3`), pipeline or transaction modes, bulk-import jobs. Most mature APIs have one; check docs, not just the method you already know.
- Collect inputs first, then call once: gather the IDs/records, send one request (or chunked requests at the API's max batch size, e.g. 100 per call), and fan results back out by key.
- Respect the API's documented batch limits and handle partial failures explicitly: a bulk response can succeed overall while individual items fail. Process the per-item statuses; don't assume all-or-nothing.
- If no batch form exists, say so in the code (comment: "API has no bulk endpoint as of vN") and bound the damage: chunk the work, reuse connections (keep-alive/session objects), apply the provider's rate limit deliberately, and make the loop resumable so item 3,001 failing doesn't restart items 1 through 3,000.
- Verify by counting requests, not by reading code: log or proxy the call count for a run over N items. The count should be ceil(N / batch_size), not N. Also check the rate-limit headers; burning N tokens for one logical operation is the failure restated.

**Red flags that you're about to violate this:**
- "The SDK method takes one ID, so I'll loop."
- "It's only a few hundred items."
- "Batching complicates the error handling."
- "I'll parallelize the per-item calls instead." (now it's a rate-limit incident on a schedule)
- "The docs example does it one at a time."
- "Each call is fast, under 100ms."

### Benchmark Before Claiming Speedups

NEVER state or imply a measured performance improvement you did not actually measure. "Optimized" without numbers just means "different."

- Performance claims require before-and-after data: a benchmark run, profiler output, timed test execution, or request latency comparison on the same inputs. Include the numbers and how they were obtained.
- If you cannot run benchmarks in this environment, describe the change in mechanical terms only ("replaces the per-item query with one batched query") and explicitly mark the performance impact as unverified. Offer a benchmark script the user can run.
- Big-O reasoning may be stated as reasoning, never converted into a wall-clock claim. "Reduces complexity from O(n²) to O(n)" is acceptable; "this makes it 100x faster" is not, unless you measured it.
- Never write speedup multipliers, percentages, or words like "dramatically faster" into commit messages, PR descriptions, comments, or summaries without a measurement behind them.
- Benchmark realistically: representative input sizes, warm-up where relevant, multiple runs. A single timing of a toy input is noise, not evidence.

**Red flags that you're about to violate this:**
- "This is obviously faster, so I'll say roughly 10x."
- "The complexity went down, so I can call it a big speedup."
- "The summary sounds better with a number in it."
- "I'll say 'significantly faster' — it's vague enough to be safe."
- "Fewer lines of code, so it must be faster."

### Bound Every In-Process Cache

NEVER create an in-memory cache, memoization map, or lookup table that grows without a size bound in a long-lived process. An unbounded cache is a memory leak that hasn't finished yet.

- Every cache needs an eviction policy: an LRU with a max entry count, a TTL-based store, or a size-aware library (`lru_cache(maxsize=N)`, `caffeine`, `lru-cache` npm package). A bare `Map`/`dict`/`HashMap` used as a cache at module or singleton scope is wrong by default.
- `@functools.lru_cache(maxsize=None)` and `@cache` are unbounded — use an explicit `maxsize`. If you copy a memoization pattern from anywhere, check what bounds it.
- Before choosing a bound, state the key cardinality: who controls the keys and how many distinct values are possible? If the key derives from user input (URLs, query strings, arbitrary IDs, payload hashes), cardinality is effectively infinite and a bound plus TTL is mandatory.
- Caches keyed by request-scoped data must be request-scoped objects, not process-level ones — let them be garbage collected with the request.
- Memoizing on unbounded-cardinality keys "for speed" with a process-level dict counts as this failure even when you don't call it a cache.
- State the chosen bound and the estimated worst-case memory (entries × approximate entry size) in a comment at the cache site.

**Red flags that you're about to violate this:**
- "There will only ever be a handful of keys."
- "maxsize=None keeps every result, which maximizes the hit rate."
- "Eviction logic is overkill for this simple helper."
- "Memory is cheap; this map stays small in practice."
- "It's just memoization, not really a cache."

### Build Big Strings with Buffers, Not Concatenation

NEVER build a large or unbounded-size string by repeated concatenation (`+=`, `s = s + piece`) in a loop. With immutable strings each append copies everything accumulated so far, making total cost quadratic in output size. Collect parts and join once, or write to a buffer/stream.

- Python: append to a list and `"".join(parts)` at the end, or use `io.StringIO`. Java/C#: `StringBuilder`. Go: `strings.Builder`. JavaScript: push to an array and `join("")` for large outputs.
- For output that leaves the process anyway (HTTP response, file), don't materialize the whole string at all; write pieces to the response/file stream as you go.
- The same quadratic structure applies to collections: `list = list + [item]` and repeated `arr.concat(x)` copy the whole accumulator per iteration. Use in-place `append`/`push`.
- Small, fixed-count concatenations are fine: gluing five known fragments together is not the problem. The rule triggers when the iteration count is data-sized (rows, lines, records, user items).
- f-strings/template literals composing one line are fine; the trap is accumulating many lines via `+=`.
- Verify with scale, not eyeballs: time the builder at 1k items and at 100k items. Linear means roughly 100x the time; if it's wildly more than that, you've got the quadratic. For a one-line check, the loop body containing `accumulator += ...` on a string is the smell.

**Red flags that you're about to violate this:**
- "+= is the most readable way to append."
- "Modern runtimes optimize string concatenation anyway."
- "The output is usually small."
- "A StringBuilder is overkill for this."
- "The tests pass and the output is correct."
- "I'll keep it simple now and optimize if it's slow." (it will be, at exactly the worst time)

### Cap Unbounded Growth in Long-Lived State

NEVER add entries to a collection that outlives the request (module-level, global, singleton, long-lived class field) without a mechanism that removes them. In a long-running process, a collection with inserts and no evictions is a scheduled out-of-memory crash; only the date is unknown.

This covers every long-lived accumulator, not just caches: dedupe sets, history/audit arrays, per-session or per-user maps, retry queues, metric label sets, connection registries.

- For every insert into long-lived state, write down what removes the entry: TTL expiry, max-size with eviction, deletion on session end/disconnect, or periodic pruning. "Nothing" is not an answer; pick one and implement it in the same change.
- Keyed-by-unbounded-input is the danger sign: keys from user IDs, URLs, request IDs, or external events grow with traffic, not with code. A map keyed by a small fixed enum is fine; a map keyed by anything callers control is not.
- For dedupe and rate-limit state, bound the window: keep IDs for N minutes or keep the last N entries, not forever. Exact-forever dedupe of an infinite stream requires infinite memory by definition.
- Tie per-entity state to the entity's end-of-life: delete the session entry on logout/expiry, drop the connection record on close, including the error paths.
- Verify under sustained load, not a single pass: run the realistic flow for thousands of iterations and confirm collection sizes and heap plateau instead of climbing. A linear memory-vs-time chart is a failed test.

**Red flags that you're about to violate this:**
- "Each entry is only a few bytes."
- "The process gets redeployed often enough."
- "I'll add eviction once it becomes a problem."
- "We need to remember every ID or dedupe might miss one."
- "Memory is cheap."
- "It's not a cache, so the cache-bounding rule doesn't apply."

### Clean Up Listeners, Timers, and Subscriptions

NEVER register a callback on something that outlives the registering scope without writing the matching teardown in the same change. Every `on`/`addEventListener`/`subscribe`/`setInterval`/`setTimeout`-that-reschedules must have a paired `off`/`removeEventListener`/`unsubscribe`/`clearInterval` wired to the owner's lifecycle.

A registration on a long-lived object (global emitter, window, document, store, socket, scheduler) pins the callback and everything its closure captures until explicitly removed. Re-running the registering code stacks duplicates.

- Write the cleanup at the same moment as the registration: return the unsubscribe function, use the framework's disposal hook (unmount/destroy/dispose effect cleanup), or use `AbortController`/`once` where supported.
- Be suspicious of any subscription created per request, per render, per reconnect, or per retry. Those paths run many times; each run must remove what the last run added or you accumulate one handler per execution.
- Keep a reference to the exact handler you registered. An inline anonymous function cannot be removed later.
- Timers that reschedule themselves need an owned cancel path; check a disposed flag before rescheduling.
- Verify by exercising the lifecycle: mount/unmount or connect/disconnect the thing 100 times and confirm handler counts and heap return to baseline (`getEventListeners`, `listenerCount()`, heap snapshot). One pass through the happy path proves nothing about accumulation.

**Red flags that you're about to violate this:**
- "The component rarely unmounts, so cleanup doesn't matter."
- "Garbage collection will take care of it."
- "I'll add the teardown in a follow-up."
- "It's just one listener."
- "The framework probably cleans this up automatically."
- "Removing it needs a reference and the inline arrow is cleaner."

### Don't Delete Slow-Looking Code Without Proof

NEVER remove or shorten a sleep, delay, retry backoff, throttle, rate limiter, debounce, lock-wait, or "redundant" call as a performance improvement without first proving why it exists and that nothing depends on it. Slowness in old code is frequently load-bearing.

Code that intentionally wastes time is usually protecting something: a downstream rate limit, a race window, an eventual-consistency lag, a CPU budget, a contractual QPS cap.

- Before deleting, investigate: `git blame` the line, read the commit message and linked ticket, search the codebase and docs for why it was added. If the history says "fix" or references an incident, assume it is load-bearing.
- Ask what breaks if it's gone: who receives the extra throughput? A database, a third-party API, a queue consumer? If you can't name the absorber and its capacity, you can't remove the limiter.
- A duplicate-looking read or refresh may be a deliberate consistency or cache-busting step. Verify with the surrounding logic before calling it redundant.
- If the delay really is obsolete, say so with evidence in the change description ("the downstream cap was lifted in v3 of the API, see X") and keep the removal in its own commit so it can be reverted alone.
- Never bundle these removals silently into a larger refactor. Flag them to the user explicitly.

**Red flags that you're about to violate this:**
- "This sleep is obviously just leftover debugging."
- "Removing the delay is the easiest speedup in this file."
- "It fetches the same thing twice, that has to be a bug."
- "There's no comment explaining it, so it can't be important."
- "My local run is much faster without it and nothing broke."
- "Rate limiting should be the server's problem, not ours."

### Don't Memoize Cheap or One-Shot Work

NEVER add memoization (`lru_cache`, `useMemo`, `computed`, hand-rolled result caches) unless all three are true: the computation is expensive, the same inputs actually recur, and the function is pure. Memoization that fails any of the three is overhead at best and a leak or stale-data bug at worst.

- Expensive: the work must cost meaningfully more than a hash-plus-dict-lookup. Arithmetic, string formatting, simple conditionals, and property access never qualify.
- Recurring: estimate the hit rate before adding the cache. If keys are unique per call (request IDs, timestamps, user-typed strings), the hit rate is zero and the cache is a pure cost — possibly an unbounded one.
- Pure: the function must depend only on its arguments. Memoizing anything that reads the clock, randomness, a database, config, or mutable state serves a frozen first answer forever. That's a correctness bug, not an optimization.
- Know the trap variants: `lru_cache` on instance methods pins `self` (and everything it references) in the cache; mutable arguments make keys unreliable; module-level caches in long-lived processes need the same bounding as any cache.
- In UI frameworks, don't reflexively wrap every value in `useMemo`/`useCallback`; the dependency tracking itself has a cost and most values are cheaper to recompute. Reserve it for measured re-render or recompute problems.
- Verify by measuring with and without, on realistic call patterns, and by logging the hit rate. A memo with a sub-50% hit rate on cheap work should be deleted.

**Red flags that you're about to violate this:**
- "Caching this can't hurt."
- "I'll memoize it while I'm here, as a best practice."
- "This might be called with the same arguments sometimes."
- "useMemo on everything keeps renders fast."
- "It reads config, but config basically never changes."
- "The decorator is only one line."

### Don't Trade Clarity for Unmeasured Speed

ALWAYS write the simple, obviously-correct version first, and keep it unless a measurement on realistic data shows it misses a stated performance requirement. Complexity is a cost you pay immediately; speculative speed is a benefit that usually never arrives.

The failure is rewriting clear code into clever code (manual buffer management, hand-rolled data structures, fast-path forks, micro-tuned loops) to chase performance nobody measured and nobody asked for.

- Default to the idiomatic standard-library solution. `set(emails)` beats a hand-rolled hash table in correctness, readability, and usually in actual speed.
- An optimization may replace simple code only when all three exist: (1) a stated requirement or budget it currently misses, (2) a measurement on realistic input proving the miss, (3) a measurement proving the complex version fixes it. Otherwise ship the simple version.
- Avoiding a known catastrophic pattern (quadratic scan on unbounded input, query in a loop) is not premature optimization. That's just not writing a bug. This rule is about adding cleverness, not about avoiding known landmines.
- If you believe a hot spot is coming, leave the simple code and add a comment noting the suspected hot spot, instead of pre-paying for it in complexity.
- When the user explicitly asks for maximum speed, still show the simple version and the measured gap before replacing it.

**Red flags that you're about to violate this:**
- "This is fine, but a really optimized version would..."
- "Allocations in this loop could add up, better pool them."
- "I'll add a fast path for the common case just in case."
- "Hand-rolling this avoids the library's overhead."
- "It's a hot path, probably." (no measurement)
- "More performant code shows better engineering."

### Exploit Existing Sort Order and Indexes

ALWAYS establish what order or keying large data already has before writing code that processes it, and use that structure. Treating sorted, keyed, or indexed data as an unordered pile pays again for organization that was already paid for upstream.

- Before processing any large dataset, answer: is it sorted (by what?), keyed, partitioned, or indexed? Check the producing query's ORDER BY, the file format's guarantees, the API's documented ordering. If it's genuinely unknown, that's a fact to confirm, not a license to scan.
- On sorted data, stop early: when scanning time-ordered logs for a window, terminate the moment entries pass the window's edge instead of reading to EOF. Range lookups use binary search (`bisect`, `sort.Search`), not linear scans.
- Two datasets sorted on the same key merge in one streaming pass with O(1) memory (the merge-join pattern: advance whichever side is behind). Don't load one side into a map just because hashing is the only join you remember.
- Don't re-sort what's already sorted — a defensive `.sort()` on a million pre-ordered rows is pure waste; assert the order instead if you don't trust it. And when you control the producer, ask for the order you need (ORDER BY in the query) rather than sorting downstream.
- For repeated lookups into a large dataset that *isn't* organized, organize it once (sort it, or build a keyed dict) and amortize, rather than scanning per lookup.
- Verify with work-done counts: log records examined per query. A window lookup on sorted data should touch roughly the window plus a seek, not the whole file.

**Red flags that you're about to violate this:**
- "A full scan always works regardless of ordering."
- "I'll sort it again just to be safe."
- "I can't be sure it's sorted, so I'll treat it as unordered." (without checking)
- "Loading it all into a dict is the standard way to join."
- "Early exit logic makes the loop more complicated."

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

### Hoist Invariant Work Out of Loops

NEVER leave work inside a loop body if it produces the same result on every iteration. Anything that doesn't depend on the loop variable gets computed once, before the loop. Inside a data-sized loop, every line is multiplied by the iteration count.

- Hoist construction of reusable objects: compiled regexes, date/number formatters, parsed schemas, template engines, lookup tables, sets used for `in` checks. Build before the loop, use inside it.
- The big one: replace per-iteration linear searches with a pre-built index. `for a in items: match = [b for b in others if b.key == a.key]` scans `others` once per item; build `by_key = {b.key: b for b in others}` once and do dict lookups inside. This turns O(n times m) into O(n + m).
- Hoist repeated property chains and conversions that can't change mid-loop (`config.settings.locale`, `str(today)`), and capture "now" once if the loop represents one logical moment.
- Function calls in the loop *condition* count too: `for i in range(len(expensive()))` and `while i < items.count()` may re-evaluate per pass depending on language. Bind to a local first.
- Do not hoist what actually varies or has per-iteration side effects; if you're unsure whether a call is pure, check it before moving it.
- Verify the multiplication: iteration count times per-call cost is the bill. A 2ms call in a 100k-iteration loop is 200 seconds. If the loop is hot, profile before/after to confirm the hoist mattered.

**Red flags that you're about to violate this:**
- "Declaring it inside the loop keeps related code together."
- "Compiling the regex is fast."
- "The runtime probably caches this internally."
- "A nested scan is fine, both lists are short." (today)
- "Extracting it before the loop makes the function longer."

### Keep Expensive Logging Out of Hot Loops

NEVER put per-iteration log statements or eagerly-built debug payloads inside loops or code paths that run per item at data scale. At a million iterations, the logging is the workload: interpolation, serialization, and write syscalls multiplied by n, plus the storage and ingestion bill downstream.

- Log per batch, not per item: progress every N items or T seconds ("processed 50,000/1,200,000"), plus a summary at the end (counts, durations, failure totals). Per-item detail belongs on the *failure* path, where volume is low and value is high.
- Never build log payloads eagerly at levels that may be disabled. `logger.debug("x=" + json.dumps(obj))` serializes even when debug is off. Use lazy forms: `logger.debug("x=%s", obj)` (formats only if enabled), `isEnabledFor`/`isDebugEnabled` guards around anything costly, or lambda/supplier APIs where the framework has them.
- Don't serialize entire objects into hot-path logs; log the identifier and the few fields that matter. The 4KB context dict per request is a cost at every layer: CPU, network, storage, ingestion pricing.
- Watch synchronous log writes in hot request paths: a blocking write to a contended stream or slow disk stalls the path itself. High-volume services need buffered/async handlers, which is a deliberate configuration choice, not a default.
- Verify two ways: profile the hot path and check the logging framework's share of CPU (more than a few percent is a finding), and estimate volume — iterations times bytes per line — before shipping. A million 200-byte lines is 200MB per run; say that number out loud first.

**Red flags that you're about to violate this:**
- "More logging means better observability."
- "It's only a debug line, it's off in production." (the f-string still runs)
- "Logging is basically free."
- "Per-item logs will help if something goes wrong."
- "I'll log the whole object so we have full context."
- "We can always lower the log level later."

### Load Config Once, Not Per Request

NEVER read or parse a static resource (config file, schema, template, translation bundle, certificate, ML model, prompt file) inside a per-request or per-item code path. Anything that doesn't change between requests is loaded and parsed once, at startup or first use, and the parsed result held in memory.

A 3ms parse done at 300 rps is most of a CPU core spent re-learning the same file. The work is identical every time; pay for it once.

- Load at module init or app startup into a constant, or behind a once-guard (lazy singleton, `functools.cache` on a zero-arg loader, `sync.Once`). Handlers consume the in-memory object.
- The transitive version counts: a `get_settings()` helper that opens a file is per-request I/O no matter how clean it looks at the call site. Check what your helpers do, not just what your handler does.
- Same rule for derived artifacts: compiled templates, parsed JSON schemas, deserialized models, loaded wordlists. Parse once, reuse the parsed form.
- If the file genuinely must be re-readable without redeploy, that's a refresh policy, not per-request reads: reload on a timer (every 30s), on a file-watch event, or on an admin signal. Decide and state the staleness tolerance; "read it every time" is the policy of not deciding.
- Startup loading also fails loudly at the right time: a missing or malformed config kills the deploy at boot instead of failing request number one in production.
- Verify at the syscall layer: run a handful of requests and confirm via strace/lsof/debug logging that the file opens once, not once per request.

**Red flags that you're about to violate this:**
- "Reading it each time guarantees we always have the latest values."
- "File reads are fast, the OS caches it."
- "Avoiding module-level state keeps the function pure."
- "It's just a small YAML file."
- "Startup loading makes the code harder to test."
- "The helper already exists, I'm just calling it."

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

### No Cache Without an Invalidation Plan

NEVER add a cache without implementing, in the same change, the answer to "how do entries stop being wrong when the source data changes?" A cache without an invalidation strategy is a staleness bug with good latency.

For every cache you introduce, all of the following must be settled and written down (in code and in a comment at the cache site):

- **Staleness budget:** how out-of-date may this value be? Get the user's answer if the code doesn't make it obvious. "Forever" is almost never the answer.
- **Invalidation mechanism:** explicit invalidation on every write path that mutates the cached data, a TTL within the staleness budget, or both. If you choose TTL-only, state the maximum staleness it permits and confirm that's acceptable.
- **Write-path audit:** list the code paths that change the underlying data and show that each one invalidates or that TTL covers it. If you can't enumerate the write paths, you are not ready to cache this.
- **Key correctness:** the key must include every input that affects the value — user ID, tenant, locale, permissions context. A missing key dimension serves one user's data to another.
- Never cache authorization decisions, feature flags, or anything security-relevant without an explicit, short TTL and user sign-off.

**Red flags that you're about to violate this:**
- "I'll just memoize this for now; invalidation can come later."
- "This data rarely changes."
- "A TTL of one hour seems reasonable." (chosen without asking what staleness costs)
- "The decorator is one line, it's basically free."
- "Restarting the process clears it anyway."

### No Quadratic Loops on User-Sized Input

NEVER nest a linear operation inside a loop when both scale with user data. The product of two user-sized dimensions is a quadratic, and quadratics on growing data are delayed outages: invisible at n=100, fatal at n=100,000.

The hidden forms matter more than the obvious double-`for`: `arr.includes(x)`, `list.index()`, `x in somelist`, `arr.indexOf`, `.find(...)`, `remove()` on a list, and string `in` on a growing haystack are all linear scans wearing one-word costumes. Any of them inside a loop over user-sized data is the bug.

- Membership tests inside loops use hashed structures: build a `set`/`Map`/`dict` of keys once (O(n)), then test in O(1). Intersection, difference, and dedupe are set operations, not nested scans.
- Pairwise "compare everything to everything" usually collapses by grouping: bucket by the join key (dict of lists), then compare within buckets. Sort-then-scan handles ranges, overlaps, and adjacency in O(n log n).
- Repeated `list.remove()`/`splice()` inside a loop is the same trap (each removal shifts the tail); collect survivors into a new collection instead.
- Loops over fixed, code-sized collections (enum values, config keys, days of the week) are exempt. Classify each loop: is n set by the code, or by users and time? Only the second kind is dangerous.
- Verify with a scaling check: run the path at n=1,000 and n=10,000. Linear-ish means about 10x the time; if it's closer to 100x, you shipped the quadratic. State the expected complexity in the PR description for any loop over user-sized data.

**Red flags that you're about to violate this:**
- "includes() is a method call, not a loop."
- "Both lists are small in every case I've seen."
- "A set feels like overkill for a simple check."
- "The nested version is more readable."
- "If it gets slow we can optimize later." (later is an incident)
- "The tests run instantly."

### No Synchronous I/O in Hot Paths

NEVER perform blocking I/O (file reads/writes, HTTP calls, DNS lookups, subprocess waits, sleeps) inside a request handler, event-loop callback, message-consumer loop, or any code that runs per request or per item. A blocking call in shared execution context stalls every request behind it, not just its own.

In event-loop runtimes (Node, Python asyncio) one sync call freezes the whole process for its duration; in threaded servers it pins a worker and drains the pool under load.

- Use the async form in the hot path: `fs.promises.readFile` not `readFileSync`, `httpx.AsyncClient`/`aiohttp` not `requests`, async DB drivers not blocking ones. In async code, a library without an async API belongs in a thread/executor offload (`asyncio.to_thread`, worker pool), not inline.
- `async def` does not make its body non-blocking. Audit what's inside: `requests.get`, `time.sleep`, `open().read()`, and sync ORM calls block the loop regardless of the function's signature.
- Sync I/O is fine at startup, in CLI scripts, in build tooling, and in one-shot batch code with no concurrency. The rule is about per-request and per-item paths, not a global ban.
- Never put `sleep` (the blocking kind) in a hot path for pacing or retry backoff; use the runtime's async delay.
- Verify under concurrency, not in isolation: fire 50 parallel requests at the path and compare p99 to the single-request latency. If concurrent latency degrades far beyond the single-call cost, something is blocking. Event-loop lag metrics and `blocked-at`-style tooling will name the line.

**Red flags that you're about to violate this:**
- "The sync version is one line and the file is tiny."
- "It's already inside an async function, so it's non-blocking."
- "This call only takes a few milliseconds."
- "requests is simpler than setting up an async client."
- "It worked fine when I tested the endpoint." (alone, once)
- "The config file read is fast on my machine."

### Optimize the Hot Path, Not the Cold Path

NEVER optimize a code path without first establishing how often it executes. Effort goes where time is actually spent: frequency times cost per call, not how slow the code looks.

The failure: optimizing startup code, CLI glue, error paths, and admin endpoints — code that runs once or rarely — while the per-request or per-item path keeps burning CPU on every single execution.

- Before touching any function, answer: how many times does this run per request, per job, or per day? Once at startup? Once per request? Once per row of a 10M-row table? Write the answer down.
- Code that runs once per process (imports, config parsing, connection setup, CLI argument handling) is almost never worth optimizing. A 200ms startup is invisible; 2ms extra per request at 1000 rps is 2 CPU-seconds per second.
- Inner loops, request handlers, serializers, and per-item callbacks are where multipliers live. Look there first.
- Verify with frequency data: a profiler's cumulative time, a request counter, or log-line counts. "This function looks expensive" is not evidence; "this function accounts for 40% of wall time under production-shaped load" is.
- If the user asks to optimize a cold path specifically, say it's cold and ask whether the per-call savings actually matter before doing it.

**Red flags that you're about to violate this:**
- "This startup function has an obvious inefficiency, I'll fix it while I'm here."
- "Every little bit helps."
- "I don't have a profile, but this nested loop looks bad."
- "Optimizing the init code is lower risk than touching the request handler."
- "The user said make it faster, and this was the easiest thing to make faster."

### Profile Before You Optimize

NEVER start optimizing until you have measurement data identifying where time is actually spent. Code that looks slow and code that is slow are usually different code.

When asked to make something faster:

- First obtain or produce a measurement: a profiler run, flame graph, `EXPLAIN ANALYZE`, request timing breakdown, or at minimum timestamped logging around the suspected sections. Ask the user for existing profiles or APM data before instrumenting by hand.
- Identify the top one or two contributors by measured time. Optimize those. Ignore everything below them, no matter how ugly it looks.
- If you cannot run a profiler in this environment, say so, add the timing instrumentation, and ask the user to run it — do not substitute guessing for measuring.
- State your finding before editing: "X% of the time is in Y, so I'm changing Y." If you can't fill in that sentence with a number, you're not ready to edit.
- Do not bundle drive-by "while I'm here" optimizations of unmeasured code into the change.

**Red flags that you're about to violate this:**
- "This nested loop is obviously the bottleneck."
- "I can see several inefficiencies, let me clean them all up."
- "Profiling would take time; the problem is clear from reading the code."
- "Even if this isn't the main cost, it can't hurt to optimize it."
- "The user said it's slow, so I'll make everything faster."

### Prove Parallelism Pays Before Adding It

NEVER add parallelism (thread pools, multiprocessing, worker fan-out, mass concurrent awaits) as a first-resort speedup. Parallelism is the last optimization, applied after the serial version is efficient and a measurement shows the workload can actually use concurrent capacity. It buys at most N times speedup and costs nondeterminism, shared-state hazards, and partial-failure handling forever.

- First identify the bottleneck of the *serial* version: CPU, disk, network latency, or a remote service. Parallelism only helps when the bottleneck has idle capacity (e.g., latency-bound I/O). If the job saturates one database or one rate-limited API, more workers add contention, not throughput.
- Exhaust the cheap wins first: batch the per-item calls, fix the quadratic, hoist the repeated work, add the missing limit. A profiler-found algorithmic fix routinely beats the best-case parallel speedup and adds no complexity.
- Know the platform ceilings before proposing: CPU-bound work in GIL-bound Python gains nothing from threads; processes have serialization overhead; event-loop runtimes parallelize I/O waits, not computation.
- If parallelism is justified, bound it: an explicit concurrency limit chosen against the downstream's capacity (connection pool size, rate limit), never unbounded `Promise.all` over a user-sized list.
- Prove it paid: measure serial-optimized vs parallel on realistic input and report both numbers, plus the downstream's error/429 rate during the parallel run. If the speedup is under ~2x or the downstream degraded, prefer the serial version.

**Red flags that you're about to violate this:**
- "This loop is slow, so I'll process items concurrently."
- "Promise.all on everything is the easy win here."
- "More workers means more throughput." (the database disagrees)
- "Threads will help even though it's CPU-bound Python."
- "We can tune the concurrency limit later."
- "Parallel code shows we took performance seriously."

### Reuse Expensive Clients and Connections

NEVER construct a connection-holding or handshake-performing object (database connection, HTTP client/session, gRPC channel, cloud SDK client, message-broker producer, search client) inside per-request or per-item code. These objects are designed to be created once and shared; they carry pools, keep-alive sockets, and token caches that only pay off across calls.

- Create clients at module scope, app startup, or via dependency injection with singleton lifetime; handlers and loop bodies receive the existing instance.
- Databases get a connection *pool* created once; per-request code borrows and returns. Constructing connections per request is both a latency tax (handshake per call) and an outage vector (max_connections exhaustion under load).
- Bare `requests.get()`/`fetch` calls in loops forfeit keep-alive: each call may re-handshake TCP+TLS. Use a `requests.Session`, `httpx.Client`, or the platform's pooled agent held across calls.
- Most official SDK clients (AWS, GCP, Stripe-style) are thread-safe and intended as singletons; check the docs and share one instance. Per-call construction can also re-trigger credential resolution against metadata endpoints, adding network calls you never see.
- If a client must be per-request (request-scoped auth), keep the *transport* shared (pooled connections under per-request credentials) where the library supports it.
- Verify at the connection layer: under a burst of requests, connection counts (`pg_stat_activity`, `netstat`/`ss` counting TIME_WAIT, client pool metrics) should be stable and small, not proportional to request count.

**Red flags that you're about to violate this:**
- "Creating the client in the function keeps it self-contained."
- "The SDK quickstart instantiates it right before the call."
- "Connections are cheap."
- "I don't want to deal with shared state or thread safety."
- "We close it right after, so nothing leaks."
- "It's one extra object per request, the GC handles it."

### State a Performance Budget Before Optimizing

NEVER begin performance work without three numbers written down: the current measurement (baseline), the target (budget), and the conditions under which both are measured. "Faster" is not a requirement; "p95 under 300ms at 200 rps on production-shaped data" is.

Without a target, every change is justifiable and none are finishable; with one, work has a direction and a stopping point.

- If the user asks for "faster" without a number, ask for one (or propose one from context: SLO, timeout, page-load guidance, job-window deadline) and get agreement before changing code.
- Record the baseline first, under stated conditions: percentile, load level, dataset size, environment. An optimization without a baseline can't prove it did anything.
- Pick changes appropriate to the gap. A 10x gap means an algorithmic or I/O-pattern problem; chasing micro-optimizations against a 10x gap is effort misallocation. A 1.2x gap might need only one targeted fix.
- Stop when the budget is met. Meeting the target and continuing to optimize is scope creep with extra risk; bank the win and move on.
- Report results against the budget: "baseline 1.8s, target 500ms, now 340ms under the same conditions" — not "significantly improved performance."
- If the budget is already met before any work starts, say so and recommend doing nothing. That is a valid and frequently correct deliverable.

**Red flags that you're about to violate this:**
- "I'll just make it as fast as possible."
- "No target was given, so any improvement is a win."
- "We're at 180ms, getting to 90ms can only help."
- "I'll measure the baseline after I finish the changes."
- "Performance work is never really done."
- "It feels faster."
