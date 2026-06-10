### Abort When a Required Step Fails

When a step fails and later code depends on its result, the operation MUST stop — return early, raise, or branch to a failure path. Logging an error is not handling it; a handler that logs and falls through to dependent code has handled nothing.

- Before writing any catch block, answer one question: can the code after this block run correctly if this step failed? If no, the block must end with `raise`, `return`, or `throw` — not fall through
- `logger.error(...)` followed by continuing into dependent code is forbidden; log AND abort, not log instead of abort
- Do not wrap each statement of a sequence in its own try/catch. A sequence with dependencies should fail as a unit: one try around the sequence, or no try at all, letting the error propagate to the caller
- "Continue on error" is valid only for genuinely independent work (e.g. optional notification after the core operation committed) — and then the code should say so: `# email is best-effort; order is already committed`
- If a function has grown a pattern of catch-log-continue at every step, that is a bug factory, not defensive coding; restructure rather than extend it
- When unsure whether downstream code depends on the failed step, assume it does and abort — an unnecessary abort is recoverable, an unjustified continue may not be

**Red flags that you're about to violate this:**
- "I'll log it so we know it happened, and keep going..."
- "The rest of the function should still run..."
- "We don't want one failure to stop the whole process..."
- "Each step gets its own try/catch for granularity..."
- "It's logged, so it's handled..."

### Await or Handle Every Promise

Every promise (and coroutine/task) must be awaited, returned, or given an explicit rejection handler. NEVER leave an async call floating — its failure has nowhere to go.

- Default to `await`. If you genuinely want fire-and-forget, you must still handle rejection: `void doWork().catch(err => logger.error("background work failed", err));` — and the `void` plus `.catch` signals the choice was deliberate
- Never use `forEach(async ...)`: forEach discards the promises, so nothing is awaited and every rejection is orphaned. Use `for...of` with `await`, or `await Promise.all(items.map(...))`
- `Promise.all` rejects on first failure and abandons the rest; when each item's outcome matters, use `Promise.allSettled` and *inspect the results* — calling allSettled and ignoring the rejected entries is the same swallowing with extra steps
- Python: every coroutine call gets `await`; every `asyncio.create_task()` result gets stored and eventually awaited (or given a done-callback that logs exceptions) — a bare `create_task` whose reference is dropped can be garbage-collected mid-flight, exception unreported
- When making a function async during a refactor, update every call site in the same change; search for calls to it that lack `await`
- Enable the linter that catches this (`@typescript-eslint/no-floating-promises`, `no-misused-promises`) when touching project config is in scope; it converts this whole class from runtime mystery to compile-time error

**Red flags that you're about to violate this:**
- "This doesn't need to block, so I'll skip the await..."
- "Logging/analytics can be fire-and-forget..."
- "forEach with an async callback handles each item..."
- "If the background task fails, it's not critical..."
- "I made the function async; the callers should still work..."

### Cap Retries and Back Off

Every retry loop MUST have three things: a maximum attempt count, exponential backoff with jitter, and a defined behavior for when attempts run out. NEVER write `while True` around a failing operation.

An unbounded or undelayed retry loop is a denial-of-service tool pointed at a service that is already struggling — and at your own thread pool.

- Cap attempts at a small explicit number (typically 3–5) chosen for the operation, not infinity by omission
- Space attempts with exponential backoff plus jitter: e.g. `delay = min(base * 2**attempt, max_delay) * random.uniform(0.5, 1.5)` — fixed 1-second sleeps synchronize clients into thundering herds
- Decide and implement what happens after the final attempt: raise the last error, return an explicit failure, enqueue for later — "loop forever" is not a final-attempt policy
- Immediate re-attempts with no delay are not retries; they are the same failure sampled five times in the same instant
- Bound the *total* time as well as the attempt count when the caller has a deadline (request handlers, anything holding a lock or connection)
- Prefer the project's existing retry utility or library (tenacity, retry middleware, urllib3 `Retry`) over a hand-rolled loop; if hand-rolling, all three elements must still be present

**Red flags that you're about to violate this:**
- "It should keep trying until the service comes back..."
- "A simple while loop with a sleep is good enough here..."
- "I'll have it call itself again on failure..."
- "Retrying immediately gives the fastest recovery..."
- "We never expect it to fail more than once or twice anyway..."

### Catch Specific Exceptions, Not Exception

ALWAYS catch the narrowest exception type that matches the failure you intend to handle. NEVER catch `Exception`, `Throwable`, or a bare `except:` for a failure you can name.

A broad catch doesn't just handle the error you expected — it intercepts every bug, typo, and unrelated failure inside the try block and feeds them all into recovery logic written for one specific case.

- Identify which exception the call actually raises and catch exactly that: `except FileNotFoundError:`, not `except Exception:`
- If two distinct failures need two distinct responses, write two catch clauses — do not merge them into one handler with the union of their recovery logic
- In languages where catch is untyped (JavaScript, TypeScript), check the error inside the handler (`if (err.code !== 'ENOENT') throw err;`) and re-throw everything you didn't plan for
- Never use a broad catch as insurance against exceptions you haven't thought of; unplanned exceptions should propagate, because the handler by definition has no correct response to them
- Broad catches are acceptable only at true top-level boundaries (request handler, worker loop, main), and even there they must log the full exception and stack, not a summary
- If you genuinely cannot determine the specific type, say so and ask, rather than silently widening the catch

**Red flags that you're about to violate this:**
- "I'll catch Exception to be safe..."
- "This covers the file-not-found case and anything else that might go wrong..."
- "A broad catch makes this more robust..."
- "I'm not sure which exception this raises, so I'll catch them all..."
- "One handler is cleaner than three..."

### Chain Exceptions When Rethrowing

When you catch an error and throw a new one, ALWAYS attach the original as the cause. NEVER construct the replacement from `e.message` alone — that deletes the original stack trace and type.

- Python: `raise DomainError("context") from e` — never `raise DomainError(str(e))` bare. Inside an `except` block, even re-raising a new error without `from` implicitly chains, but be explicit: `from e` for wrapping, `from None` only when hiding the cause is a deliberate, commented decision
- JavaScript/TypeScript: `throw new DomainError("context", { cause: e })` — never `throw new Error(e.message)`
- Java/C#: pass the original as the constructor's cause/innerException argument: `throw new ServiceException("context", e)`
- Go: wrap with `%w` so `errors.Is`/`errors.As` still work: `fmt.Errorf("loading config: %w", err)` — `%v` or `err.Error()` breaks unwrapping
- The wrapper's own message should add context the original lacked (operation, identifiers) — duplicating `e.message` into the wrapper adds nothing and tempts you to skip chaining
- To re-throw unchanged, use the bare form that preserves the original: `raise` (Python), `throw;` (C#), re-`throw err` (JS) — not a reconstruction of it
- Ensure log formatters print the full cause chain (`exc_info=True`, logging `err.cause`); a chain nobody prints is a chain nobody sees

**Red flags that you're about to violate this:**
- "I'll wrap the message in our custom error class..."
- "new Error(e.message) keeps the important part..."
- "The message tells you everything the stack would..."
- "Converting to our error type means building a fresh one..."
- "The original error isn't needed once we've translated it..."

### Check Exit Codes on Every Subprocess Call

Every external command's exit status MUST be checked, and a nonzero status must stop dependent work. A subprocess call without a checked exit code is an operation whose failure you have chosen not to know about.

- Python: use `subprocess.run([...], check=True)` so failure raises `CalledProcessError`; if you must inspect instead, branch on `result.returncode` explicitly. Never use bare `os.system(cmd)` without checking its return value
- Bash: start scripts with `set -euo pipefail` so failed commands, unset variables, and failed pipeline stages stop the script; for commands allowed to fail, make it explicit (`if ! grep -q pattern file; then ...` or `cmd || true` with a comment saying why)
- Node: check `error` in `exec`/`execFile` callbacks before touching stdout; with `child_process.spawnSync`, check `.status`; prefer promisified versions that reject on failure
- On failure, capture and surface stderr — `pg_dump: connection refused` is the actual error; "command failed with exit 1" alone is a context-free message
- Failure must abort dependents: don't upload the archive when the dump failed, don't restart the service when the build failed
- A command's success must be judged before its output is used; parsing stdout of a failed command processes garbage
- Pipelines hide failures: in bash, without `pipefail`, `cmd1 | cmd2` reports only `cmd2`'s status

**Red flags that you're about to violate this:**
- "subprocess.run executes it; that's what matters..."
- "These commands basically never fail..."
- "I'll grab stdout — if it ran, there's output..."
- "Adding check=True might break callers that expect no exception..."
- "The script is simple; it doesn't need set -e..."

### Distinguish Missing From Failed Lookups

"It doesn't exist" and "I couldn't check" are different outcomes and must stay different all the way up the stack. NEVER catch an infrastructure error and return the not-found value.

Absence is an answer you may act on. Failure is the absence of an answer — acting on it means acting on nothing.

- `except ConnectionError: return None` in a lookup function is forbidden; let infrastructure errors raise, return None only for genuine absence
- Keep the distinction in return shapes: absence → `None`/empty/`NotFound`; failure → exception or error result. If a function can produce both, the types must differ — never the same sentinel
- In HTTP clients: 404 means absent (act accordingly, don't retry); 5xx/timeout means unknown (retry or propagate, never treat as absent)
- Cache lookups: a cache *miss* means "go compute"; a cache *connection failure* should be handled as an explicit degrade decision, not silently folded into miss-and-recompute without a decision that the backend can take the load
- Be paranoid wherever absence triggers action — account creation, access control, deletion, reconciliation: before acting on "not found," confirm the code path can only reach that branch via a successful lookup
- Deny-by-default security checks must distinguish too: "permission check errored" should fail the request loudly, not quietly evaluate as "no permissions" (or worse, "no restrictions")

**Red flags that you're about to violate this:**
- "If the fetch fails, None is the safe thing to return..."
- "Either way, we don't have the user, so it's the same case..."
- "The caller already handles None, so I'll reuse that path..."
- "A failed check means they don't have access, which is safe..."
- "If the upstream call errors we can treat it as no data..."

### Don't Collapse Distinct Errors Into One Response

Failures that mean different things to the caller MUST produce distinguishable outcomes. NEVER funnel validation errors, not-found, permission failures, and downstream outages into one generic catch-all response.

- In request handlers, map error categories before the catch-all: `except ValidationError: 400 with field details`, `except NotFound: 404`, `except PermissionDenied: 403`, `except UpstreamTimeout: 503 (retryable)` — then `except Exception: 500` for the truly unexpected
- The catch-all is for bugs only; if a known failure type is reaching it, that's a missing clause, not acceptable coverage
- Distinguishable means machine-distinguishable: different status codes / error codes (`{"error": {"code": "INVALID_EMAIL"}}`), not different prose in the same 500
- Never return 500 for a client mistake — the caller can fix a 400; a 500 tells them to wait and retry, which is exactly wrong for bad input
- Same rule beyond HTTP: CLIs should use distinct exit codes or distinct stderr messages per failure class; RPC handlers should use the protocol's status taxonomy (e.g. gRPC `INVALID_ARGUMENT` vs `UNAVAILABLE`), not `UNKNOWN` for everything
- Expected domain failures may carry detail to the caller; the generic 500 path should log full detail server-side but expose no internals (no stack traces or query text in responses)

**Red flags that you're about to violate this:**
- "One except clause at the bottom covers every case..."
- "It's all errors to the client anyway..."
- "Returning 500 for everything is simpler and safer..."
- "The client can read the message if they need specifics..."
- "I'll add granular handling later; generic works for now..."

### Don't Convert Exceptions to Boolean Returns

NEVER catch an exception and return `False`/`True` as the function's whole account of what happened. One bit cannot carry the failure's type, cause, or context — and unlike an exception, it can be silently ignored.

- Default: don't catch at all. Let the operation raise; the caller gets the full exception with type and stack, and *cannot accidentally ignore it*
- If the API must not throw, return a structured result, not a bool: `Result[Receipt, SendError]`, `(ok, error)` where `error` is the exception object, or a small dataclass with `success`, `error_type`, `detail` — something the caller can branch on and log faithfully
- Never write `except Exception: return False` — the broad catch plus the bit means even bugs (AttributeError, TypeError) report as the operation politely declining
- Status-code conventions (`return -1`, `return 0` on error) carry the same flaw plus ignorability; don't introduce them into languages with exceptions
- If you find callers writing `if not f(): log("f failed")`, that's the signal the boolean is starving them — fix `f` to raise or return structured errors rather than enriching the guesswork
- Booleans are fine for actual predicates (`is_valid(x)`, `exists(key)`) where False is an *answer*; the rule is about failure reporting, where False is a *cover-up*

**Red flags that you're about to violate this:**
- "Returning a bool keeps the interface simple..."
- "The caller only needs to know if it worked..."
- "True/False is cleaner than making them handle exceptions..."
- "If it fails, they can just check the logs..."
- "I'll return False for now and we can add detail later..."

### Don't Let Cleanup Errors Mask the Original

Cleanup code (finally, defer, catch-side rollback, context-manager exits) runs when an exception may already be in flight. It must neither replace that exception nor erase it.

- Never put a `return`, `break`, or `continue` inside a `finally` block — in Python and JavaScript these silently discard the propagating exception
- Cleanup that can itself fail (closing broken connections, rolling back on a dead transaction, deleting temp files) must be wrapped so its failure is logged at WARN but does not propagate: `finally: try: conn.close() except Exception: logger.warning("close failed during error handling", exc_info=True)`
- The original exception always wins: if both the operation and its cleanup fail, the operation's error is the one that must escape; attach the cleanup error as suppressed/secondary if the language supports it (Java `addSuppressed`, Python sets `__context__` automatically — make sure logs print it)
- In rollback handlers, guard the rollback: `except Exception: try: tx.rollback() except Exception: log; raise` — re-raise the *original* error outside the inner try
- Prefer constructs that handle this correctly for you: Python context managers / `contextlib.ExitStack`, Java try-with-resources, Go `defer` with explicit error capture — over hand-written finally chains
- Cleanup must be written for the failure case: assume the resource may already be broken, half-open, or gone when cleanup runs

**Red flags that you're about to violate this:**
- "The finally block just closes things, it can't fail..."
- "I'll return the result from finally so it always returns..."
- "rollback() is safe to call anywhere..."
- "If cleanup throws, that's the error we should see anyway..."
- "I don't need a nested try inside an except block..."

### Don't Let Error Handlers Throw

Code inside a catch/except block must be written defensively — it runs at the worst possible moment, against the least predictable inputs, and if it throws, it destroys the very error it was supposed to report.

- Never chain optional fields optimistically in a handler: `e.response.status_code` crashes when `response` is None (true for timeouts/connection errors in most HTTP libraries); write `status = e.response.status_code if e.response is not None else "no response"`
- Don't assume error payloads parse: `e.response.json()["message"]` assumes a body, valid JSON, and a `message` key — three assumptions about a *failure*; fall back to raw text, truncated: `body = e.response.text[:500] if e.response else ""`
- In JavaScript, `catch (e)` receives anything — not necessarily an Error: check before using (`e instanceof Error ? e.stack : String(e)`); accessing `e.response.data.message` off an unknown deserves optional chaining and a fallback
- Keep handlers short and dumb: log the exception object itself with the language's built-in formatting (`logger.error("request failed", exc_info=True)`, `logger.error(err)`) rather than hand-assembling messages from its internals — the built-in path doesn't crash on missing fields
- Anything nontrivial a handler does (cleanup calls, notification sends, metrics) can itself fail; if the handler must do real work, guard that work so the original exception still gets reported and re-raised first or regardless
- Test the handler with the *poorest* error available (timeout with no response, non-JSON body), not just the rich one

**Red flags that you're about to violate this:**
- "The error will have a response object with the details..."
- "I'll pull message out of the error body for a nicer log line..."
- "Status code is always there on a failed request..."
- "The catch just formats and logs; nothing to go wrong..."
- "The SDK's exceptions all have a .code attribute..."

### Escalate When Every Batch Item Fails

A batch loop that tolerates per-item failures MUST also detect systemic failure and abort. One hundred percent failure is not a data-quality issue — it means the system is broken, and the loop should stop and say so immediately.

- Track failures during the run, not just after: keep a failure count and check it against a threshold as the loop proceeds
- Abort early on consecutive failures from a cold start: if the first N items (e.g. 10–25) all fail, stop — the probability that your first 25 records are all individually bad is negligible compared to the probability that the credential, schema, or endpoint is broken
- Abort on failure *rate* mid-run: pick a threshold defensible for the dataset (e.g. >20% after a meaningful sample) and stop when crossed, raising an error that states the rate and a sample of the underlying exceptions
- When failures share one exception type and message, say so in the abort error — "all 25 failures: AuthenticationError" hands the operator the diagnosis
- Stopping early preserves options: items not yet attempted can be retried cleanly after the fix; items churned through a broken dependency may have half-executed side effects
- Distinguish error classes where possible: infrastructure errors (connection, auth, timeout) should trip the abort threshold faster than data errors (validation), because they're never the item's fault
- The threshold values are judgment calls — make them named constants with a comment, so they're visible and adjustable, not buried magic

**Red flags that you're about to violate this:**
- "The per-item handler already covers failures..."
- "Skip and continue — that's what batch resilience means..."
- "Counting failures mid-run is overengineering..."
- "Even if many fail, processing the rest is still progress..."
- "We'll see the failure totals in the summary at the end..."

### Fail Fast on Startup Errors

If a service cannot do its job, it must refuse to start. NEVER catch a required-dependency failure at boot and continue to a "running" state — crash loudly while the deploy is still watching.

- Validate at startup, before reporting healthy: required config present and well-formed, database reachable, required credentials accepted, migrations at expected version
- A failed required initialization must terminate the process with a clear message (`FATAL: cannot connect to postgres at db:5432: connection refused`), not log a warning and set the client to None
- Do not lazily initialize required dependencies to dodge boot failures; lazy init converts a deploy-time crash (cheap, attributed, auto-rolled-back) into a request-time outage (expensive, mysterious)
- Optional dependencies may degrade — but "optional" is a product decision, stated in code (`# feature X disabled without redis; core flows unaffected`), not a label applied to whatever happened to fail
- Readiness endpoints must reflect real ability to serve: a process that opened its port but lacks its database is not ready and must not report ready
- Crash-looping on a down dependency is acceptable behavior under orchestration — the orchestrator backs off and retries, the deploy fails visibly, the old version keeps serving; do not "fix" the crash loop by swallowing the error

**Red flags that you're about to violate this:**
- "The service should still start even if the DB is down..."
- "I'll initialize it lazily on first use..."
- "A warning at boot is enough; it might recover..."
- "Health checks should pass so the deploy goes through..."
- "Crashing at startup looks bad..."

### Handle Errors at the Layer That Can Act

Catch an error at the layer that has both the context to decide what it means and the power to do something about it. Low-level helpers should add context and propagate — NEVER absorb errors and return degraded values on behalf of callers they know nothing about.

- A reusable function (HTTP helper, DB accessor, file util) must not decide that its own failures are tolerable; it doesn't know whether the caller is rendering a widget or moving money
- Default behavior for low layers: let the exception propagate, optionally wrapping it with added context (`raise StorageError(f"writing {path}") from e`) — do not catch-log-return-None
- Catch at the layer where a meaningful decision exists: the request handler that can return a 503, the job runner that can reschedule, the orchestration code that knows whether this step is optional
- One error, one handling site: if the bottom layer already logged-and-absorbed, the top layer can never apply its policy; if both handle, you get duplicate handling and contradictory outcomes
- "Adding error handling" to a utility usually means *removing* the decision from it: wrap-and-rethrow with context is the utility's whole job
- If a helper must offer a lenient mode, make it explicit at the call site (`fetch(url, on_error="return_none")`) so each caller opts in knowingly rather than inheriting a hidden policy

**Red flags that you're about to violate this:**
- "I'll handle the error right where the request is made..."
- "The helper can just log it and return None..."
- "Callers shouldn't have to worry about failures..."
- "This keeps the exception from bubbling up..."
- "Every function should handle its own errors..."

### Keep Errors Typed, Don't Stringify Them

NEVER reduce an error to its message string when passing it to code that may need to react to it. Callers branch on types and codes; strings are for humans at the end of the line.

`str(e)` keeps the prose and throws away everything programmable: the class, the error code, the structured fields, the cause chain.

- When converting an exception into a return value, return the exception object or a structured error (type/code + fields), not `str(e)`: `return Err(e)` or `{"error": {"code": "EMAIL_TAKEN", "field": "email"}}` — never `{"error": str(e)}`
- Never write code that branches on message text — `if "duplicate key" in str(e)` or `e.message.includes("timeout")` — branch on the exception class, `e.code`, `errno`, or HTTP status instead
- In Result/Either-style code, the error channel's type should be an error type or union of them, not `string`
- At API boundaries, serialize errors as structured data: a stable machine-readable `code` plus a human `message` — clients must be able to react to the code without parsing the message
- Stringify only at terminal sinks: log formatting, console output, UI display — places where no further code will make decisions based on the error
- If a third-party library forces you to receive strings, convert them to typed errors at that boundary once, instead of letting strings spread inward

**Red flags that you're about to violate this:**
- "I'll just return the error message so the caller knows what happened..."
- "Checking if the message contains 'not found' handles that case..."
- "A string error field keeps the response shape simple..."
- "str(e) captures everything important..."
- "The caller only needs to display it anyway..."

### Keep Try Blocks Narrow

A try block should cover one operation that can fail, not a whole function. Wrap the specific call you expect to raise; leave everything else outside.

When fifty lines share one handler, the handler can't say what failed, can't recover meaningfully, and catches bugs it was never written for.

- Put the try around the single failing operation: the `requests.get`, the `json.loads`, the file open — not the function body. Lines that can't raise the expected error don't belong inside
- One try block per distinct failure meaning: if the DB query and the HTTP call fail differently and matter differently, they get separate try blocks (or separate functions), not shared residence in one
- The narrower the block, the more the handler knows: `except requests.Timeout:` around just the call can say "payment-status check timed out for order {id}" and choose the right recovery — a function-wide handler can say only "error"
- Don't indent existing code into a new giant try as a way of "adding error handling" — that's adding error hiding; identify the fallible lines and wrap those
- Pure logic between fallible operations (arithmetic, dict access, formatting) stays outside try blocks so its bugs crash loudly instead of impersonating operational failures
- If a function needs five try blocks, that's often a sign it's five functions; refactoring beats one umbrella catch

**Red flags that you're about to violate this:**
- "I'll wrap the whole function to make sure nothing escapes..."
- "One try/except at the top level keeps it readable..."
- "Everything in here is risky, so the whole thing goes in the try..."
- "Indenting the body into a try is the quickest way to add handling..."
- "The handler can figure out what failed from the message..."

### Log Caught Errors at Error Level

Log levels are routing, not tone. A real failure logged below ERROR is invisible to the alerting and dashboards that watch for failures — record it at the severity that gets it seen.

- A caught exception representing a failed operation is logged at ERROR, with the exception and stack attached: `logger.error("payment sync failed for order %s", oid, exc_info=True)` / `logger.error("sync failed", err)` — not debug, not info, not a message without the exception
- Never use `print(e)` or `console.log(err)` for failures in code that has a logger; use the logger at error level (`console.error` at minimum in plain JS)
- Reserve the lower levels for what they route to: WARN for degraded-but-handled (retry succeeded, fallback engaged deliberately), INFO for normal operations, DEBUG for diagnostics — a failure that broke the operation is none of these
- Don't inflate either: logging expected, handled conditions at ERROR (every cache miss, every validation rejection of user input) trains humans and alert thresholds to ignore the channel — severity inflation and severity deflation both end in missed incidents
- The test for level: who needs to act? Someone should be alerted → ERROR. Worth noticing in review → WARN. Nobody → INFO/DEBUG
- When you downgrade an existing `logger.error` to reduce noise, you are editing alerting behavior; say so explicitly rather than slipping it into an unrelated diff

**Red flags that you're about to violate this:**
- "I'll print the exception so it shows up during testing..."
- "Debug level keeps production logs clean..."
- "It's caught, so warning seems more accurate than error..."
- "console.log is fine; it all goes to the same place..."
- "I don't want this to trigger alerts, so I'll log it lower..."

### Log or Rethrow, Never Both

Each error should be logged exactly once, at the layer that finally handles it. When you rethrow, do not also log — the layer that ultimately catches will do the logging.

A catch block has two jobs to choose from: take responsibility (handle and log) or pass responsibility (rethrow, optionally adding context). Doing both at every layer turns one failure into a log storm.

- `catch (e) { logger.error(e); throw e; }` is the antipattern — pick one: handle-and-log, or rethrow
- When rethrowing through a layer, add context to the exception itself (wrap with cause: `raise JobError(f"syncing user {uid}") from e`), not to the logs — context travels with the error to the single log site
- Log at the boundary where the error stops propagating: the top-level request handler, the job runner, the consumer loop — once, with the full chained stack trace
- Exception: a layer that handles the error (retries successfully, falls back deliberately) may log it at WARN/INFO as a handled event — because for layers above, that error no longer exists
- Trust the propagation: "log here too in case it gets swallowed upstream" means you suspect a swallowing bug — fix that bug instead of pre-compensating with duplicate logs
- When adding logging to existing code, check whether the exception is already logged above or below before adding another site

**Red flags that you're about to violate this:**
- "I'll log it here for visibility and rethrow so the caller can deal with it..."
- "Extra logging never hurts..."
- "Each layer should record that it saw the error..."
- "Better to log twice than risk losing it..."
- "I'll add logger.error to every catch block for consistency..."

### Never Ack Messages You Failed to Process

An ack — or a 2xx to a webhook — is a receipt meaning "this work is done and you may forget it." NEVER send that receipt for work that failed.

- Ack only after processing succeeds; never in a `finally`, never before the work, never in a catch-all path. `finally: msg.ack()` acks failures by construction
- On transient failure (downstream outage, timeout), nack/reject or let redelivery happen — that's the queue's retry mechanism working, not a problem to silence
- On permanent failure (message that can't ever parse, violates invariants), route to the dead-letter queue or a quarantine store with the error attached — explicitly, not by ack-and-log
- Distinguish the two in the handler: `except TransientError: msg.nack(requeue=True)` vs `except PoisonMessage: dlq.send(msg, error=e); msg.ack()` — acking is correct *only after* the message has been safely parked elsewhere
- Webhook handlers: return 2xx only after durably accepting the event (processed, or persisted/enqueued for processing); on failure return 5xx so the provider retries. Never return 200 from a catch block to "stop the retries" — those retries are your recovery
- Poison-message loops (same message redelivered forever, crashing each time) are solved with max-delivery counts and DLQ routing — queue features that exist for this — not by acking the failure
- If redelivery means reprocessing, the handler needs idempotency anyway; build that rather than avoiding redelivery by lying

**Red flags that you're about to violate this:**
- "Ack in finally guarantees we never get stuck on a message..."
- "Returning 200 stops the provider from hammering us..."
- "It failed and it'll just fail again, so ack and move on..."
- "The error log preserves what happened..."
- "Redeliveries are flooding the consumer; acking everything calms it down..."

### Never Blind-Retry Non-Idempotent Operations

Before adding retries to any operation, answer: if this executed twice, would the second execution be harmless? If not, you MUST NOT retry it until you've made it safe — a timeout may mean the first attempt actually succeeded.

A timeout is not "it didn't happen." It's "I don't know what happened." Retrying on top of an invisible success is how duplicates are born.

- Classify before wrapping: reads and idempotent writes (PUT to a fixed state, DELETE by id, upsert-by-key) may retry freely; creates, charges, sends, increments, and appends may not — by default
- To make a write retryable, give it an idempotency key: pass the provider's idempotency header (most payment and messaging APIs support one), or use a client-generated unique key with a uniqueness constraint so replays collide instead of duplicating
- Without an idempotency mechanism, a timed-out non-idempotent call must not be blindly re-sent: surface the ambiguous outcome to the caller, or query the resource first ("did order with this reference get created?") before re-attempting
- Distinguish failure classes: "connection refused before sending" is safe to retry even for writes (the request never arrived); "timeout awaiting response" is the dangerous ambiguity
- Never put a generic retry decorator/interceptor on a client that performs writes without auditing every write endpoint it covers
- Apply the same test to queue redelivery and cron re-runs: anything that may execute twice needs the same idempotency design, not just HTTP calls

**Red flags that you're about to violate this:**
- "I'll wrap this API call in the standard retry helper..."
- "Timeout means it failed, so retrying is safe..."
- "Duplicates are an edge case we can clean up later..."
- "The payment provider probably dedupes on their side..."
- "Three retries on the order endpoint will fix the flakiness..."

### Never Coerce Parse Failures to Zero

When a value fails to parse, the result is a missing/invalid value — NEVER a fabricated `0`, `""`, `NaN`-coerced default, or epoch date. Zero is a real value with real arithmetic consequences; an unparseable input is not evidence the value was zero.

- `except ValueError: price = 0.0`, `parseInt(s) || 0`, `Number(x) || 0`, `int(x or 0)` — all forbidden as parse-failure handling; they manufacture data
- On parse failure, do one of: raise with the offending value and field (`f"row {n}: can't parse price {raw!r}")`; mark the field explicitly invalid/missing (`None`, `Optional`, a validation error list); or route the record to a reject/quarantine path — never proceed with a fabricated value
- In JavaScript, never use `|| 0` after a numeric parse — `NaN` is falsy, so the idiom converts every failure to 0 silently; check `Number.isNaN(n)` and handle it as the failure it is
- A genuine default is only valid when *absence* is expected and the default is a documented business rule (`quantity defaults to 1 when omitted`) — and even then, apply it for absent values, not for present-but-garbage values, which must error
- Dates deserve special paranoia: a parse fallback of `new Date(0)` or `datetime.min` plants events in 1970; fail or null, never epoch
- If invalid values are written anywhere persistent, the corruption outlives the bug; treat parse coercion near a database write or file output as the highest-severity form of this mistake

**Red flags that you're about to violate this:**
- "Zero is a safe default if the number won't parse..."
- "|| 0 handles the NaN case..."
- "The import shouldn't fail over one bad cell..."
- "Empty string is harmless if decoding fails..."
- "We can clean up weird values later; let's get the data in..."

### Never Fall Back to Empty Collections on Error

NEVER catch an error and return an empty list, dict, set, or array in its place. An empty collection is a successful result that claims "zero items exist" — it is not an error representation.

The moment a failure becomes `[]`, every downstream consumer treats it as truth: reports show zero, syncs propagate zero, deletes reconcile against zero.

- If a fetch, query, or parse fails, propagate the error: re-raise it, or return an explicit failure value (`Result`/`Either`, or raise a domain exception) — never `return []` or `return {}`
- Do not write `data = fetch() or []`, `items = response.get('items', [])` on a failed response, or `catch { return [] }`
- An empty collection is only a valid return when the operation genuinely succeeded and genuinely found nothing — those are the only conditions under which you may return one
- If a caller truly wants degrade-to-empty behavior (e.g. optional decorative data), that decision belongs at the call site, written explicitly by the caller — not buried inside the fetching function as a default for everyone
- When you see existing code consuming a possibly-failed fetch, do not "fix" a crash by defaulting the input to empty; fix the error path instead

**Red flags that you're about to violate this:**
- "Returning an empty list keeps the return type consistent..."
- "Downstream code handles empty lists fine, so this is safe..."
- "If the API is down we can just show nothing..."
- "I'll default to [] so the loop doesn't blow up..."
- "Empty is a reasonable neutral value here..."

### Never Leave Empty Catch Blocks

NEVER write a catch/except block whose body does nothing. `except: pass`, `catch (e) {}`, and discarding a returned error are all the same act: deleting evidence that something failed.

An empty catch does not handle an error. It hides one. The failure still happens on every execution; it just no longer reports itself.

- Every catch block must do at least one of: recover meaningfully (retry, use a documented alternative path), re-raise, or log with the full exception and then take a deliberate next step
- If an exception is genuinely safe to ignore, prove it in code: catch the narrowest possible type, and add a comment stating exactly why ignoring it is correct (e.g. `except FileExistsError: # mkdir race, directory already created by another worker`)
- "Safe to ignore" plus broad `Exception` is a contradiction; you cannot know an error is ignorable without knowing which error it is
- Never add try/except around code just to make a traceback disappear during your own testing; the traceback was the useful output
- If you don't know how to handle the error, don't catch it. Let it propagate. An unhandled exception with a stack trace is strictly more useful than silent wrong behavior

**Red flags that you're about to violate this:**
- "I'll wrap this in a try/except so it doesn't crash..."
- "This error isn't important for the main flow..."
- "Adding pass here makes the tests go green..."
- "It's just a best-effort operation, failures are fine..."
- "I'll suppress this for now and we can add handling later..."
- Typing `catch` with no plan for what goes inside it

### Never Retry Client Errors

Retry ONLY errors that can plausibly succeed on a second attempt without anything changing. NEVER retry an error caused by the request itself.

Retrying a deterministic failure doesn't add resilience — it multiplies load, delays the real error, and disguises a bug as flakiness.

- Retryable: network timeouts, connection resets, HTTP 502/503/504, and 429 (only while honoring the `Retry-After` header if present)
- Not retryable: HTTP 400, 401, 403, 404, 405, 409, 422 — validation failures, bad credentials, missing resources, and conflicts will fail identically every attempt; fail immediately and surface the response body
- The same taxonomy applies outside HTTP: retry a database deadlock or connection drop; never retry a constraint violation, a syntax error, or a serialization failure of your own payload
- Write the retry condition as an explicit allowlist of retryable statuses/exception types, not `except Exception` around the whole call
- A 401/403 must propagate loudly — it usually means an expired or misconfigured credential, and every retry delays that discovery
- If a library's built-in retry is in use (urllib3 `Retry`, axios-retry), configure its `status_forcelist`/condition explicitly; defaults are not a decision

**Red flags that you're about to violate this:**
- "I'll retry on any exception to make it resilient..."
- "Five attempts with backoff should handle most failures..."
- "A 400 might be transient on their end..."
- "Retrying auth errors covers token race conditions..."
- "It's simpler to retry everything than to classify errors..."

### Never Swallow Cancellation Exceptions

Cancellation and shutdown signals are control flow, not errors. NEVER let a catch block absorb them — they must always propagate.

- Python: never write a bare `except:`; use `except Exception:` at the broadest, which lets `KeyboardInterrupt` and `SystemExit` pass. Never use `except BaseException:` unless you re-raise unconditionally
- Python asyncio: if you must catch `asyncio.CancelledError` (to clean up), re-raise it after cleanup — a coroutine that swallows it breaks `cancel()`, `wait_for`, and task-group shutdown for every caller
- .NET: in a broad catch, let `OperationCanceledException`/`TaskCanceledException` escape — `catch (Exception ex) when (ex is not OperationCanceledException)` — or rethrow it first
- Java: catching `InterruptedException` requires either rethrowing it or restoring the flag with `Thread.currentThread().interrupt()` — never catch-and-continue, which erases the interrupt
- JavaScript: in broad `catch` blocks around abortable operations, check for `AbortError` (`e.name === 'AbortError'`) and re-throw it rather than treating it as a failure to retry or log as an error
- Worker loops that intentionally survive errors (`while True: try/except Exception`) must still die on cancellation — test that Ctrl+C and SIGTERM actually stop the process
- Never retry an operation that failed due to cancellation; the caller asked it to stop, not to try harder

**Red flags that you're about to violate this:**
- "A bare except makes this loop bulletproof..."
- "I'll catch BaseException to be thorough..."
- "CancelledError is an exception, so the error handler should handle it..."
- "Catch, log, continue — the worker must never die..."
- "I'll treat the abort like any other failed request and retry..."

### No Silent Defaults When Config Loading Fails

NEVER substitute a hardcoded default when required configuration is missing or fails to parse. If config can't be loaded, the program must refuse to start and say exactly what's missing.

A silent default means the app runs with settings nobody chose, in an environment where nobody knows the real config was ignored.

- Required settings (database URLs, API keys, secrets, service endpoints, security flags) must hard-fail when absent: raise at startup with the setting name, e.g. `raise RuntimeError("DB_HOST is not set")` — never `os.getenv("DB_HOST", "localhost")`
- If a config file fails to parse, propagate the parse error; do not fall back to a `DEFAULT_CONFIG` object
- Never default a secret, credential, or security toggle, in any environment, ever — no `"dev-secret"`, no `verify=False` fallback
- Defaults are legitimate only for genuinely optional tuning values (page size, log format), and each one must be a documented decision: define it once in a central config schema with a comment, not inline at the call site
- Distinguish "missing" from "invalid": an unset optional value may take its documented default; a *malformed* value must error, because someone tried to set it and failed
- When asked to "make startup more robust," robustness means clearer failure messages, not fewer failures

**Red flags that you're about to violate this:**
- "I'll default to localhost so it works out of the box..."
- "If the config is missing we can fall back to sensible values..."
- "This keeps the app running even when the env isn't set up..."
- "A default secret is fine for development..."
- "getenv with a fallback is the standard pattern..."

### Put Context in Every Error Message

Every error message must answer three questions for a reader who cannot see the code: what operation failed, on what specific thing, and why. NEVER raise or log a message that is only a category, like "Invalid input" or "Operation failed."

Error messages are read in logs and alerts, far from the code that produced them. A message without identifiers cannot be acted on.

- Include the identifiers: `raise ValueError(f"order {order_id}: quantity must be positive, got {qty}")` — not `raise ValueError("invalid quantity")`
- Include the offending value (truncated/sanitized if large) and the expectation it violated, so the reader learns both what happened and what should have happened
- Name the operation and the target in failures of I/O: `f"failed to write checkpoint to {path}"`, not `"write failed"`
- Make messages distinguishable: if two different failure sites produce the identical string, rewrite one — grep-ability of a unique message is a debugging feature
- Never include secrets, tokens, passwords, or full PII in messages; include the *identifier* of the thing, not its sensitive contents
- When wrapping a lower-level error, add the context the lower level lacked (which record, which attempt, which config) instead of restating its message

**Red flags that you're about to violate this:**
- "A short generic message keeps it clean..."
- "The variable name makes the problem obvious..."
- "Whoever sees this can check the code..."
- "'Failed to process' covers all the cases in this function..."
- "I'll reuse the same error message as the function above..."

### Raise, Don't Return Null on Failure

When an operation fails, raise an exception (or return an explicit error value in Result-style codebases). NEVER return `None`/`null`/`nil` as a stand-in for "something went wrong."

Null carries no information — not what failed, not why, not even that a failure occurred. It just relocates the crash to whichever distant line touches it first.

- `except Exception: return None` is forbidden; let the exception propagate, or wrap it with context and re-raise
- Returning null is legitimate only when null is a *meaningful answer to the question asked* — `find_user()` returning None for "no such user" is fine; `find_user()` returning None for "database unreachable" is a lie about what happened
- If a function can return null for absence, failures must still raise — never collapse "not found" and "couldn't look" into the same None
- Don't null-pad partial failures: if 3 of 10 fields failed to parse, raising beats returning an object with three silent Nones inside it
- In Go, return a non-nil `error` rather than a nil result with a nil error; in Rust/FP-style code, use the `Result`/`Option` types instead of sentinel nulls
- If you find yourself adding `if x is None: return None` to a caller, stop — you are extending a null-propagation chain; fix the producer to raise instead

**Red flags that you're about to violate this:**
- "Returning None is gentler than raising..."
- "The caller can check for None if they care..."
- "This way the function never throws..."
- "None is a natural way to say it didn't work..."
- "I'll pass the None along like the function below me does..."

### Raise Specific Error Types, Not Generic

When raising an error, raise a type a caller could catch selectively. NEVER raise the base class — `Exception`, `Error`, `RuntimeError` with prose — for a failure that has a name.

The type is the API of the failure. Prose is for humans; the class is what code branches on.

- First, reuse: check whether the project defines domain exceptions (`NotFoundError`, `ValidationError`) or whether a built-in fits exactly (`ValueError` for bad arguments, `KeyError`, `TimeoutError`, `FileNotFoundError`) — raise the most specific existing fit
- If a distinct failure has no type, define one — a one-line class (`class QuotaExceededError(Exception): pass`) is cheap, and inheriting from the project's base exception keeps it catchable in bulk too
- Distinct failures that callers will treat differently need distinct types: not-found, permission-denied, and quota-exceeded raised as one shared class with different messages forces callers back to string matching
- In JavaScript/TypeScript, subclass `Error` (`class RateLimitError extends Error`) or set a stable `code` property; never throw plain strings or object literals, which lack stacks and instanceof identity
- Give structured fields to the type, not just the message: `QuotaExceededError(limit=100, retry_after=30)` lets handlers act on the numbers without parsing prose
- Don't go taxonomically wild either: a new exception class per call site is noise — one type per *distinct caller-visible failure*, organized under a small module hierarchy

**Red flags that you're about to violate this:**
- "raise Exception with a clear message is enough..."
- "Defining a custom exception class is overkill here..."
- "The message tells the caller exactly what went wrong..."
- "I'll use RuntimeError; it's basically for things like this..."
- "Callers can check the text if they need to distinguish..."

### Roll Back Transactions on Error

Inside a transaction, any error means the whole transaction rolls back. NEVER catch an exception mid-transaction and continue to commit — partial units of work must not become permanent.

- The transaction is the try scope: one try around the whole unit of work, with `except: rollback(); raise` — not per-statement catches that fall through to commit
- Never call `commit()` in a `finally` block or after a swallowed exception; commit belongs only on the path where every statement succeeded
- Prefer the language's transactional scope constructs, which encode commit-on-success/rollback-on-error correctly: `with session.begin():` (SQLAlchemy), `transaction.atomic()` (Django), `BEGIN/COMMIT` wrappers in your DB library, `TransactionScope` in .NET — over hand-wired commit/rollback
- If you catch an error inside a transaction to handle it (e.g. fall back to an alternate write), the handling must stay transaction-aware: either the transaction is still valid in your database (it isn't in PostgreSQL after an error, without savepoints), or you roll back / roll back to a savepoint first
- Always wire the error path: an opened transaction must reach exactly one of commit or rollback on every code path, including early returns — leaked open transactions hold locks and poison pooled connections
- Side effects that can't roll back (HTTP calls, emails, file writes) don't belong inside the transaction; do them after commit, or design compensation for them

**Red flags that you're about to violate this:**
- "I'll catch the error on this statement so the rest of the transaction completes..."
- "Commit in finally guarantees we never lose the work..."
- "Logging the failed update is enough; the other writes are fine..."
- "Rollback throws away the successful statements, which seems wasteful..."
- "I'll handle the constraint violation inline and keep going..."

### Surface Partial Failures in Batch Operations

A batch operation that skips failed items MUST surface those failures in its result — not only in its logs. NEVER return success, exit 0, or say "done" when items failed.

Skipping a bad item can be the right call; pretending it didn't happen never is.

- Return a result object with counts and identities: `{succeeded: 8800, failed: 200, failures: [{id, error}, ...]}` — not `None` or `true`
- The per-item catch must record *which* item and *which* error into that result, narrow-typed where possible — `except ValidationError as e: failures.append((record.id, e))`
- If any items failed, the overall outcome must say so: non-zero exit code or a distinct "completed with errors" status, so schedulers and alerting can see it without parsing logs
- Logging each skip is good but is not surfacing; logs are diagnostics, the return value is the contract
- Make the caller confront the result: the summary line ("Imported 8,800 of 9,000; 200 failed — IDs in failures list") belongs in the job output, the API response, or the CLI's stdout
- Failed items must remain recoverable: keep their IDs (or the rows themselves) somewhere a retry can find them — a skipped item that exists only as a log line is unrecoverable in practice
- Do not cap or sample the failure list silently; if you truncate the detail, state the true total count

**Red flags that you're about to violate this:**
- "I'll log skipped rows and keep the return type simple..."
- "The job completed, so it should exit zero..."
- "Failures are in the logs if anyone needs them..."
- "A few bad records shouldn't change the success status..."
- "I don't want to complicate the function signature for edge cases..."
