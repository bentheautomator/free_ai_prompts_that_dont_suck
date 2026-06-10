### Ack Webhooks Fast, Do Work Async

A webhook handler's job is to durably accept the event and return 2xx within a couple of seconds. NEVER run slow or multi-step business logic inline before responding to a webhook: providers time out slow responses, count them as failures, redeliver into your now-busy service, and eventually disable the endpoint.

- In the handler do only: verify the request, persist the event (insert into a table or publish to a queue), return 200. Everything else happens in a worker that consumes what you persisted.
- The persistence step must be durable before you respond. Acking and then doing the work from memory means a crash after the 200 silently loses the event, and the provider will never resend it — you told it delivery succeeded.
- No outbound API calls, email sends, file generation, or fan-out inside the handler. One slow third party in that path becomes your timeout.
- Status codes signal delivery, not business outcome. If the event is stored, return 200 even though processing hasn't happened yet; report processing failures through your own job retries and alerts, not the webhook response.
- Keep the synchronous path's only failure modes to "could not verify" and "could not persist" — those are the cases where you genuinely want the provider to retry.
- If the work is truly trivial (set one flag, one indexed update), inline is fine. The moment there's a second side effect or any network call, move it behind the queue.

**Red flags that you're about to violate this:**
- "The processing only takes a second or two, well within the timeout."
- "Adding a queue for this one webhook is over-engineering."
- "I'll do the work first so I can return an accurate status code."
- "The provider's timeout is 30 seconds, we have plenty of room."
- "If processing fails, returning 500 gets us a free retry from the provider."
- "I'll respond 200 immediately and then keep processing in this request."

### Add Jitter and Backoff to Every Retry

NEVER retry immediately or on a fixed interval. Every retry policy MUST use exponential backoff with randomized jitter and a retry budget. Failures are correlated — when a dependency breaks, all callers fail together, and unjittered retries form synchronized waves that keep the dependency down.

- Use exponential backoff with full jitter: `sleep(random(0, min(cap, base * 2^attempt)))`. The randomness is not optional garnish — it is the mechanism that decorrelates callers; exponential backoff alone still produces (spreading) waves.
- Cap total attempts (typically 2–4) and cap total elapsed time against the caller's deadline. Retrying past the point where anyone is still waiting for the answer is pure load, zero value.
- Retry only what can plausibly succeed on retry: timeouts, 5xx, connection resets, broker redelivery hints. Never retry 4xx (except 429), validation failures, or non-idempotent operations that may have partially succeeded — see your idempotency rules first.
- Honor `Retry-After` on 429/503 over your own schedule. The server is telling you its actual recovery plan.
- Count your layers: if the SDK retries 3x, your service retries 3x, and the client retries 3x, one failure costs 27 requests. Pick one layer to own retries (usually the lowest one with idempotency context) and make the others fail fast.
- For high-traffic paths, add a circuit breaker or retry-budget (e.g., retries may be at most 10% of requests) so a hard-down dependency gets near-zero traffic instead of maximum traffic.

**Red flags that you're about to violate this:**
- "I'll just retry after a one-second sleep."
- "Jitter is overkill for an internal service."
- "More retries means more reliability." (Means more load on whatever is already failing.)
- "Retry until it succeeds."
- "The SDK probably doesn't retry on its own." (Check. It does.)
- "It's fine, the dependency can handle a few extra requests." (Times every caller. In sync.)

### Apply Backpressure When Downstream Falls Behind

Every producer MUST have a feedback mechanism that slows or stops production when its downstream cannot keep up. "Publish succeeded" only means the broker took the bytes; without backpressure, a slow consumer becomes an unbounded backlog and a multi-hour recovery.

- Use the signals the transport gives you: publisher confirms and blocked-connection callbacks (RabbitMQ), `max.in.flight` and buffer-full errors (Kafka), stream `write()` returning false plus `drain` (Node), bounded channels that block the sender (Go). Never swallow them and keep sending.
- For HTTP and gRPC, treat 429 and 503 with `Retry-After` as commands, not errors to log: reduce send rate, then ramp back gradually.
- Watch queue depth or consumer lag and act at a threshold: pause intake, shed low-priority work, or return 429 to your own callers. Propagating pressure upstream to the original client is the design goal — somebody at the edge can actually slow down.
- Cap in-flight work in the producer (semaphore, bounded pool). "Accept everything and buffer" just moves the unbounded queue into your process.
- Decide explicitly what is droppable under pressure (metrics, low-value events) versus what must block (orders, payments). Dropping by accident is an outage; dropping by policy is load shedding.
- Set TTLs on time-sensitive messages so a backlog drains stale work instead of processing Tuesday's "live" notifications on Thursday.

**Red flags that you're about to violate this:**
- "Publish is async, so the producer doesn't need to care."
- "The queue absorbs spikes, that's what it's for."
- "The consumer keeps up fine." (Today. At current traffic. While healthy.)
- "I'll retry the publish until it succeeds." (Into a full broker. Harder.)
- "Slowing down the producer would hurt throughput."
- "We'll add rate limiting if it becomes a problem."

### Bound Every Queue and Buffer in Services

NEVER create an unbounded in-process queue, channel, or backlog buffer in a long-running service. An unbounded queue is a memory leak with a business justification: any sustained gap between producer and consumer rates grows it until the process dies, losing everything it held.

- Give every queue an explicit capacity: `queue.Queue(maxsize=N)`, a bounded channel, a deque with `maxlen`, a bounded executor work queue. Pick N from real numbers (memory per item × tolerable backlog), not a vibe.
- Decide at design time what happens when the queue is full, and implement exactly one of: block the producer (backpressure), reject the new item with an error the caller sees, or drop with a counter/metric. Silent unbounded growth is not on the list.
- Arrays and maps used as backlogs count: a `pendingEvents.push(...)` with a periodic flush is a queue, and it needs a cap and an overflow policy too.
- If losing queued items on crash is unacceptable, the buffer belongs in a durable broker or database, not process memory. A big in-memory queue is the worst of both: unbounded risk and zero durability.
- Bound thread pools and their submission queues together — an executor with a bounded pool but unbounded task queue still grows without limit.
- Emit queue depth as a metric. A queue you cannot observe will surprise you.

**Red flags that you're about to violate this:**
- "The consumer is fast, the queue will stay near empty."
- "I'll make the channel buffer huge so the producer never blocks."
- "Adding a maxsize means handling the full case, which complicates this."
- "It's just a temporary buffer for bursts."
- "We can add a limit later if memory becomes a problem."
- "Dropping items feels wrong, so I'll keep everything."

### Cap Concurrency on Parallel Fan-Out

NEVER launch parallel work whose concurrency equals the input size. `Promise.all(items.map(...))`, `gather(*all_tasks)`, or a goroutine per element means production data decides your parallelism. Always run fan-out through an explicit concurrency limit.

- Use a bounded executor: a worker-pool/limit utility (`p-limit`, `p-map` with `{concurrency: N}` in Node), `asyncio.Semaphore` around each task in Python, a semaphore or worker-pool of N goroutines reading from a channel in Go, `errgroup.SetLimit(n)`.
- Pick the limit from the bottleneck, not vibes: respect the target's documented rate limit, your connection pool size, and per-host socket limits. Single digits to low tens is the usual answer for external APIs; defaulting to something like 10 beats defaulting to ∞.
- Make the limit a named constant or config value so load tests and incidents can tune it without a code hunt.
- Handle partial failure deliberately: use `Promise.allSettled` / collect per-item results rather than first-error-aborts-everything, and report which items failed so the batch can be partially retried.
- Compose with your other limits: each parallel call still needs a timeout, and retries inside fan-out must be jittered — N parallel naive retries is the storm with a head start.
- If items number in the hundreds of thousands, fan-out in the request path is the wrong tool entirely — enqueue the work for background workers instead.

**Red flags that you're about to violate this:**
- "Promise.all is the idiomatic way to parallelize."
- "There are only ever a few items in this list." (Enforced where?)
- "More concurrency means it finishes faster." (Until the rate limiter, pool, or kernel disagrees.)
- "Goroutines are cheap, spawn one per row."
- "The downstream service can handle it, it's internal."
- "I'll deal with failures by letting the whole batch throw."

### Checkpoint Long-Running Jobs So They Can Resume

Any job that processes a large dataset or runs longer than a few minutes MUST persist its progress and resume from the last checkpoint after a restart. Assume the process WILL be killed mid-run — by a deploy, an eviction, or an OOM — and design for the rerun, not just the run.

- Persist a durable cursor as work completes: the last processed ID, timestamp watermark, batch number, or offset, stored in a database or the job's own state table — not in process memory, not in a local file on an ephemeral disk.
- On startup, read the cursor and continue from it. Starting from zero must be an explicit operator choice, never the default.
- Process in ordered, deterministic batches (by primary key range or stable cursor) so "resume from checkpoint" has a well-defined meaning. Unordered `OFFSET` pagination shifts under you.
- Advance the checkpoint only after the batch's work is durably complete — checkpoint-then-process loses the batch on a crash between the two.
- Make each item's processing idempotent anyway (skip-if-done guard or upsert), because a crash mid-batch means the batch boundary will be replayed.
- Record per-item failures and continue; don't let item 41,007 kill a million-item run. Park failures for later review.
- Log progress (`processed 412000/1900000, cursor=812345`) so operators can distinguish "slow" from "stuck" and estimate completion.

**Red flags that you're about to violate this:**
- "The job should finish in one go, it's a single script."
- "If it fails we can just run it again from the start."
- "I'll keep a counter of where we are." (In memory. Where counters go to die.)
- "Restarts are rare, this isn't worth the complexity."
- "I'll wrap the whole thing in one big transaction." (Hours-long transactions are their own incident.)
- "We only need to run this once."

### Dedupe Webhook Deliveries by Event ID

ALWAYS treat webhook delivery as at-least-once and deduplicate by the provider's event ID before running side effects. Every serious webhook provider redelivers on timeout, error, or internal retry; a handler that acts once per delivery will act twice per event.

- Extract the provider's unique event ID (e.g. `event.id`, a delivery GUID header) and record it in durable storage with a unique constraint as part of processing. If the insert conflicts, the event was already handled: return 200 and do nothing.
- Make the dedup check atomic with the work, or at minimum insert-first: `INSERT ... ON CONFLICT DO NOTHING` and only proceed if the row was inserted. A read-then-act check loses to two deliveries arriving concurrently, which providers genuinely do.
- Return success for duplicates. Returning an error tells the provider the delivery failed and earns you another redelivery of the event you just declined.
- Dedup storage must be shared and durable: a database table or shared store, never an in-process `Set` (wiped on restart, invisible to other replicas).
- If the provider sends no event ID, derive a deterministic one from stable payload fields and document the choice.
- Keep processed-ID rows at least as long as the provider's maximum retry window (check the docs; days, not minutes), then prune by timestamp.

**Red flags that you're about to violate this:**
- "The provider sends each event once, that's the whole point of webhooks."
- "Duplicates would only happen if we error, and we won't error."
- "I'll keep a set of seen IDs in memory."
- "Checking for an existing order status first is enough deduplication."
- "Returning 409 on duplicates seems more semantically correct."
- "Dedup is something we can add when it becomes a problem."

### Drain In-Flight Work Before Shutdown

Every server and worker MUST shut down gracefully: on SIGTERM, stop accepting new work, finish in-flight work within a deadline, then exit. NEVER let process exit be the default termination behavior — orchestrators send SIGTERM on every deploy, scale-down, and node rotation, so abrupt exit drops live requests routinely, not rarely.

- HTTP servers: on SIGTERM, stop accepting new connections, let in-flight requests complete (use the framework's graceful close — `server.close()`, `srv.Shutdown(ctx)`, uvicorn/gunicorn graceful timeout), then exit 0.
- Workers: finish or cleanly abort the current message before exiting. Stop polling first, then drain. A message killed mid-processing should be unacked or returned so another worker picks it up.
- Always bound the drain with a deadline shorter than the orchestrator's kill grace period (Kubernetes defaults to 30s before SIGKILL). Drain forever and you get SIGKILLed mid-drain anyway, which is the original bug with extra steps.
- During the drain, the readiness probe must start failing so the load balancer stops routing new traffic. Draining while still in the pool means you're rejecting requests you were just handed.
- Don't start un-finishable work near shutdown: check a shutting-down flag before picking up new jobs.
- Wire this into the entrypoint now, not "when we productionize." It's ten lines.

**Red flags that you're about to violate this:**
- "The orchestrator handles shutdown for us."
- "Requests are fast; the odds of one being in flight are low."
- "I'll add signal handling once the core logic works."
- "SIGKILL can happen anyway, so graceful handling is pointless."
- "Deploys happen at night when traffic is low."
- "The job runner framework probably does this out of the box."

### Give Background Jobs a Deadline and Heartbeat

Every background job MUST have a maximum runtime, enforced from outside the job's own code, and long-running jobs MUST emit progress heartbeats. A job with no deadline that hangs is invisible: it throws nothing, retries never, and holds its worker slot forever.

- Set an explicit per-job-type timeout in the worker framework (Celery `time_limit`, BullMQ timeouts, a context deadline wrapping the handler in Go) — enforced outside the job, because a wedged job cannot check its own watch.
- Size the deadline from observed runtime (e.g., p99 × 3), not a universal "1 hour to be safe." A deadline that never fires is a deadline you don't have.
- On expiry, kill the job and route it through your normal failure path — retry if transient, dead-letter after max attempts — so "hung" degrades into the failure mode you already handle, instead of a fourth state nobody handles.
- Long jobs should heartbeat: update a `last_progress_at` timestamp or extend a claim lease as batches complete. A sweeper that flags jobs whose heartbeat is stale catches hangs in minutes; a deadline alone catches them at the deadline.
- Alert on both signals: deadline kills (something regressed) and stale heartbeats (something is wedged right now).
- Since deadline kills interrupt mid-work, the job body must be idempotent and resumable — see your idempotency and checkpointing rules, or kills become duplicate side effects.
- Fleet-level tell: worker slots pinned at 100% while throughput falls means hangs are accumulating.

**Red flags that you're about to violate this:**
- "The job finishes in a few seconds, a timeout is pointless."
- "Each HTTP call inside already has a timeout, so the job can't hang." (Loops, deadlocks, and CPU spins disagree.)
- "I'll have the job check elapsed time periodically." (The wedged job checks nothing. Enforce externally.)
- "If it hangs we'll see errors." (Hangs are precisely the absence of errors.)
- "I'll set it to 24 hours so it never kills legitimate work."
- "The framework probably has a default limit." (Check it. It's usually infinity.)

### Keep Rate-Limit Counters Out of Local Memory

NEVER enforce a rate limit, quota, or usage counter with process-local state in a service that can run more than one instance. Each replica counting privately means the effective limit is `limit × replicas`, it resets on every deploy, and it loosens exactly when you scale up under attack.

- Keep enforcement counters in a shared store with atomic operations: Redis `INCR` + `EXPIRE` (atomically, via pipeline or Lua), a token-bucket script, or your gateway's built-in distributed limiter. The check-and-increment must be one atomic step — read-modify-write from N replicas undercounts under concurrency.
- This covers every counter with consequences: per-user rate limits, plan quotas, failed-login lockouts, "max N concurrent jobs per account," coupon redemption caps, anything billed.
- Prefer enforcing at a layer built for it when available (API gateway, ingress rate limiting, CDN) and keep application-level limits for business quotas the edge can't see.
- Decide the limiter's failure mode explicitly: if the shared store is down, fail open (allow, log loudly) for revenue paths and fail closed for abuse/security paths (lockouts). Silence is the only wrong option.
- Local memory is acceptable only as a layered pre-filter (e.g., a per-instance cap to shed egregious floods before the Redis hop) — never as the authoritative count, and say so in a comment.
- Include the window design: fixed windows allow 2× bursts at boundaries; use sliding windows or token buckets when the limit actually matters.

**Red flags that you're about to violate this:**
- "A simple in-memory map keeps this dependency-free."
- "We only run one instance of this service." (Confirm the deployment, then ask about next quarter.)
- "Per-instance limiting is roughly the same thing."
- "Sticky sessions mean each user hits the same pod anyway." (Until a pod dies, scales, or deploys.)
- "It's just a soft limit, accuracy doesn't matter." (Then why is billing reading it?)
- "Redis adds latency to every request." (One INCR is sub-millisecond; quota fraud is not.)

### Keep Session State Out of Process Memory

NEVER store cross-request state — sessions, auth tokens, rate-limit counters, feature locks, shared caches — in process memory in a service that can run more than one instance. Assume every service will be horizontally scaled and restarted; in-process state silently diverges between replicas and evaporates on every deploy.

- Sessions and tokens go in a shared store (Redis, the database) or in signed tokens carried by the client. A `sessions = {}` dict at module scope is a bug, not a placeholder.
- Rate limiters and quotas count in a shared store with atomic operations. Per-process counters multiply every limit by the replica count.
- Anything mutated by one request and read by another (dedupe sets, "already sent" flags, in-flight job registries) must live somewhere all replicas can see.
- In-process caches are acceptable only for data that is immutable or harmlessly stale, and the cache must be a pure performance layer: the code must be correct with the cache removed.
- Do not "fix" this with sticky sessions unless explicitly asked. Stickiness hides the problem until a replica dies and takes its state with it.
- When local state is genuinely fine (per-request scratch data, config loaded at boot), keep it local. The rule is about state that outlives one request.

**Red flags that you're about to violate this:**
- "A simple in-memory map is fine for now; we can move it to Redis later."
- "This service probably only runs as a single instance."
- "The load balancer likely has sticky sessions enabled."
- "It's just a counter, it doesn't need to be exact."
- "Adding Redis for this one feature feels like over-engineering."
- "It works in staging, and staging mirrors production."

### Lock Cron Jobs Against Overlapping Runs

NEVER schedule a recurring job without deciding what happens when a run is still going at the next tick. By default, most schedulers will happily start a second concurrent copy, and two copies of the same job double-process whatever the job touches.

- Guard every scheduled job with a mutual-exclusion mechanism that works across instances: a database advisory lock, a Redis lock with expiry (e.g., Redlock/SETNX with TTL), or the scheduler's own policy (Kubernetes `concurrencyPolicy: Forbid`, Quartz `@DisallowConcurrentExecution`, `flock` for plain cron).
- A boolean in process memory is not a lock — the next run may start on a different replica, and a crashed run leaves the boolean stuck.
- Give every lock a TTL or heartbeat so a crashed holder doesn't block the job forever. A lock that can't expire converts "double run" into "no runs ever again."
- Decide skip vs. queue explicitly: usually the right behavior is to skip the tick and log it (the work will be picked up next run). Queuing missed ticks recreates the pileup.
- Emit a metric or log when a run is skipped due to the lock, and alert if runs are skipped repeatedly — that means the job can no longer finish within its interval and needs attention.
- If the job processes rows, also make the selection atomic (`SELECT ... FOR UPDATE SKIP LOCKED` or claim-by-update) as defense in depth.

**Red flags that you're about to violate this:**
- "The job only takes a few seconds, it'll never overlap."
- "Cron handles that." (It doesn't.)
- "I'll set a flag at the start and clear it at the end."
- "There's only one instance of this service." (Until the next scale-out or blue-green deploy.)
- "Overlap is harmless here, the operations are probably idempotent."
- "I'll just make the interval longer."

### Make Retried Service Handlers Idempotent

NEVER write a handler that performs a non-idempotent mutation (charge, send, create, increment) without a mechanism to detect and absorb duplicate requests. Networks retry. Clients retry. Load balancers retry. Assume every mutating request will arrive at least twice.

- Accept an idempotency key (header or body field) on every mutating endpoint that creates side effects. If the caller is internal, derive one deterministically (e.g. `order_id + action`).
- Persist the key in the same atomic operation as the mutation — a unique constraint on the key, not a read-then-write check. `SELECT then INSERT` has a race window; `INSERT ... ON CONFLICT` does not.
- On a duplicate key, return the stored result of the first execution with the same status code — not an error. The retrying client should be unable to tell it was a replay.
- Pass the idempotency key through to downstream providers that support it (payment APIs, email APIs) so the protection extends past your own database.
- Don't fake idempotency with "check if a similar record exists in the last 5 minutes" heuristics. Time windows are not identity.
- Naturally idempotent operations (set status to X, PUT full resource) don't need keys — but verify they actually are, including any side effects they trigger.

**Red flags that you're about to violate this:**
- "The client will only call this once."
- "The frontend disables the button after submit, so duplicates can't happen."
- "I'll check if the record exists first, then insert."
- "This is an internal endpoint, nothing retries internal calls."
- "Adding idempotency keys is over-engineering for this feature."
- "The payment provider probably handles duplicates on their side."

### Never Assume Clocks Agree Across Services

NEVER write logic whose correctness depends on two machines' clocks agreeing, or on one machine's clock never jumping. Clocks drift, skew, and step backwards under NTP correction; any cross-service timestamp comparison inherits that error.

- Never order events from different producers by their embedded wall-clock timestamps. Use a single authority instead: a sequence from one database (`SERIAL`, one node's monotonic counter), the broker's partition offset, or explicit version numbers.
- For elapsed time within one process, use the monotonic clock (`time.monotonic()`, `process.hrtime()`, Go's `time.Since`), never `now() - then` with wall time — wall time is allowed to jump while you're measuring.
- For expiry and freshness across services, build in tolerance: accept reasonable clock skew on validation windows (as JWT validators do with leeway), and prefer "issued by the same authority that validates" over "issued by clock A, judged by clock B."
- Let one clock decide per decision: use the database's `NOW()` for created/expires columns compared by database queries, rather than mixing application time into database comparisons.
- For deduplication, last-write-wins, and conflict resolution, use versions or vector-ish counters, not timestamps. Two writes 5ms apart on machines skewed 50ms resolve in the wrong order, silently.
- Always store and transmit timestamps in UTC with timezone-explicit types; local-time ambiguity stacks a second error source on top of skew.
- Treat "the timestamps say this is impossible" as expected telemetry (negative durations, future events) — clamp, log, and continue rather than crashing.

**Red flags that you're about to violate this:**
- "Both servers run NTP, their clocks are basically identical."
- "I'll order the events by their timestamps."
- "The token expires in 30 seconds, plenty of margin."
- "A negative duration can't happen, I'll assert against it."
- "I'll compare the API's timestamp against our server's now()."
- "Milliseconds of drift don't matter here." (Until the NTP daemon dies and it's minutes.)

### Never Assume Message Order From Queues

NEVER write a queue consumer that depends on messages arriving in the order they were produced. Competing consumers, retries, redeliveries, and multi-partition brokers all reorder messages, so a consumer that assumes sequence will corrupt state in production.

- Make each message self-sufficient: include the entity ID and either a version number, sequence number, or authoritative timestamp from the producer, so the consumer can decide what to do without trusting arrival order.
- Use last-write-wins guarded by version: reject or ignore a message whose version/sequence is older than what is already stored (`UPDATE ... WHERE version < :incoming`). Never blindly apply the latest arrival.
- For genuine state machines, treat out-of-order arrivals as expected input: either park the early message for redelivery, or store it and reconcile when the missing predecessor arrives. Do not throw on "impossible" transitions.
- If strict ordering is truly required, get it from the broker explicitly (FIFO queue with message group ID, Kafka partition keyed by entity ID, single consumer per key) and say so in a comment. Do not get it implicitly from "there's only one consumer right now."
- Remember that redelivery reorders even single-consumer setups: a nacked message goes to the back of the line while newer messages sail past it.

**Red flags that you're about to violate this:**
- "Events are published in order, so they arrive in order."
- "There's only one consumer, so ordering is guaranteed."
- "The paid event always comes after the created event."
- "I'll throw an exception if the state transition is invalid — it can't happen."
- "Kafka is ordered." (Only per partition, only with the right key.)
- "Handling out-of-order events makes the consumer too complicated."

### Never Hardcode Service Hostnames or URLs

NEVER embed hostnames, ports, or full URLs for services, databases, brokers, or third-party APIs as string literals in application code. The address of a dependency is environment configuration, and a literal that is correct on one machine is wrong on every other one.

- Read every dependency address from configuration: environment variables, a config file selected per environment, or service discovery. `PAYMENTS_API_URL=http://localhost:8081` belongs in `.env.development`, not in the code.
- Define each address exactly once, in a config module, and import it. Five call sites reading `process.env.PAYMENTS_API_URL` directly is five chances for a typo'd fallback.
- Fail fast at startup if a required address is missing. Do not default to localhost in the code (`process.env.API_URL || "http://localhost:3000"`) — that fallback silently activates in any misconfigured environment, including production.
- This covers more than HTTP: database hosts, Redis endpoints, Kafka bootstrap servers, SMTP relays, webhook callback URLs your service hands out, and CORS origins.
- Keep the scheme and port in the config value too. Hardcoding `https://` + configurable host breaks local TLS-less setups; hardcoding `:8081` breaks everything else.
- Provide a `.env.example` documenting every required variable so new environments are configured by checklist, not by archaeology.

**Red flags that you're about to violate this:**
- "I'll just hardcode it for now and we can extract it later."
- "It's localhost in dev anyway, this makes the example runnable."
- "It's an internal service, the address never changes."
- "I'll add a sensible localhost fallback so it works out of the box."
- "It's only used in this one place."
- "The staging URL is fine here, this code only runs in staging."

### Never Store Request State in Globals

NEVER store request-scoped data — current user, tenant, locale, auth token, trace ID, the request object itself — in a global, module-level, static, or singleton-instance variable. The process is shared by all concurrent requests; anything stored process-wide will be read by the wrong request under load, which means one user seeing another user's data.

- Pass request state explicitly through function parameters, or carry it in the mechanism built for this: `contextvars` (Python async), `AsyncLocalStorage` (Node), `context.Context` (Go), request-scoped DI beans (Java/Spring), `flask.g`/`request` (which are context-local, not true globals).
- Never use thread-locals in async runtimes: one thread interleaves many requests, so thread-local is just a slower global.
- Keep fields like `currentUser`, `requestId`, or `tenantId` off singleton services. Singletons may hold configuration and connections (immutable or internally synchronized) — never per-request values.
- In Python, never use mutable default arguments (`def f(items=[])`) or module-level mutable containers as scratch space; they persist across requests for the life of the worker.
- Treat caches keyed without a tenant/user component as the same bug: a "current permissions" cache with a global key serves the first caller's permissions to everyone.
- If a global must be mutated at request time, stop — that is the design error, not an implementation detail to synchronize.

**Red flags that you're about to violate this:**
- "I'll store the user in a module variable so I don't have to pass it everywhere."
- "Setting it in middleware and reading it later is cleaner."
- "Each request gets its own thread, so a static field is fine." (Not in async. Not with pooled threads.)
- "It's just a temporary scratch variable."
- "This service is a singleton, so I'll put the request on it."
- "We've never seen wrong data in dev or staging." (One user at a time never collides.)

### Never Treat Task Enqueue as Task Completion

NEVER report or record async work as done at the moment you enqueue it. Enqueue means "accepted," not "completed" — only the worker that finishes the job may write the completion state.

- Model the lifecycle explicitly: `pending` → `processing` → `completed` / `failed`, with the enqueueing code writing `pending` and only the worker writing terminal states. A boolean `done` flag has no room for the truth.
- Return honest responses: `202 Accepted` with a task/status reference, `"status": "queued"`, not `"sent"` / `"created"` / `"done"`. If the caller needs to know the outcome, give them a way to learn it (status endpoint, webhook, polling token) instead of a premature verdict.
- Update the record from the worker on both success and failure, including a failure reason. A job that dead-letters must leave a visible `failed` state behind — pair this with your dead-letter handling.
- Enqueue durably relative to your transaction: if you write `pending` and enqueue separately, a crash between the two strands the record. Use the transactional-outbox pattern or enqueue-after-commit with a reconciliation sweep for stuck `pending` rows.
- Sweep for zombies: anything `processing` or `pending` beyond a sane age is an alarm, not a curiosity — it means a worker died mid-job or a message was lost.
- Never let downstream logic trigger off the optimistic flag ("invoice_sent → start dunning timer"); trigger off the worker-written completion event.

**Red flags that you're about to violate this:**
- "Enqueue basically never fails, and workers always run."
- "I'll mark it done here so we don't need a second update."
- "The user wants to see 'sent', not 'queued'."
- "We can assume the background job succeeds."
- "A status column is overkill, a boolean is fine."
- "If the job fails it'll retry, so it's as good as done."

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

### Release External Resources on Termination Signals

Handle SIGTERM (and SIGINT) in every long-running process, and use the handler to release every external resource the process holds. The OS reclaims memory and file descriptors at death; it does NOT release distributed locks, leases, claimed jobs, registrations, or temp files — those persist as ghosts unless you release them.

- Register a shutdown handler at startup (`signal.signal`/`process.on('SIGTERM')`/`signal.NotifyContext`) that runs an ordered cleanup: stop taking new work, then release in reverse-acquisition order — un-claim in-progress job rows (reset to `pending`), release distributed locks and leases, deregister from service discovery, close broker consumers cleanly (so partitions rebalance now, not at session timeout), delete temp/spool files, end metered third-party sessions.
- Bound the cleanup with a deadline shorter than the platform's kill timeout (Kubernetes default: 30s to SIGKILL). A hung cleanup step must not block the rest — best-effort each item, log what released and what didn't.
- Belt and braces: every lock, lease, and claim must ALSO have a TTL or heartbeat so a SIGKILL, OOM, or kernel panic — which no handler survives — heals itself. The signal handler makes recovery instant; the TTL makes it inevitable.
- Make startup tolerant of your own ghosts: on boot, reap expired claims and stale registrations left by less graceful ancestors.
- Exit with a meaningful code after cleanup so the supervisor can distinguish graceful from crashed.
- Don't acquire what you can't release: if a resource has no TTL and no cleanup path, that's a design flaw to fix before shipping, not after the first node drain.

**Red flags that you're about to violate this:**
- "The OS cleans everything up when the process exits."
- "Deploys are rare, a stale lock once in a while is fine."
- "The TTL will expire eventually." (Eventually = your job is down until then, every deploy.)
- "Signal handling is platform boilerplate, not app logic."
- "Ctrl-C works fine locally."
- "We'll just manually delete the lock if it gets stuck." (You have just scheduled future 2 a.m. work.)

### Release Pooled Connections on Every Code Path

Every acquired pooled resource MUST be released on every exit path — success, exception, early return, timeout, cancellation. Use the language's scope-guaranteed construct, never a release call at the end of the happy path.

- Use the guaranteed-cleanup idiom: `try/finally` or context managers (`with pool.connection()`) in Python, `try { ... } finally { client.release() }` in Node, `defer rows.Close()` / `defer conn.Release()` immediately after acquisition in Go, try-with-resources in Java. Acquisition and guaranteed release should be adjacent lines.
- Prefer APIs that scope the resource for you: `pool.query()` over manual `connect()`/`release()` when you don't need a transaction; helper functions like `withConnection(fn)` that own the acquire/release pair so callers can't get it wrong.
- In transactions, ensure rollback-then-release on the error path; releasing a connection with an open failed transaction back to the pool poisons the next borrower with "current transaction is aborted" errors.
- Set pool guardrails as defense in depth: acquisition timeout (so exhaustion produces loud fast errors, not silent hangs), max lifetime, and idle timeout. Log or alert on pool wait time and checked-out count — a leak is visible in those metrics weeks before the outage.
- Audit any early `return`, `continue`, or thrown exception between acquire and release — each one is a leak path unless the release is scope-guaranteed.
- The same rule covers file handles, locks, semaphores, and HTTP response bodies (unclosed bodies pin connections in keep-alive pools).

**Red flags that you're about to violate this:**
- "I release it at the end of the function."
- "The error case is rare, it won't matter."
- "The pool will clean up idle connections eventually." (Checked-out isn't idle. It waits forever.)
- "Adding try/finally everywhere is noisy."
- "GC will close it when the object is collected." (Maybe. Eventually. After the outage.)
- "We restart nightly anyway."

### Route Failed Jobs to a Dead-Letter Queue

Every background job MUST have an explicit terminal failure destination: after a bounded number of retries, the job and its full payload land in a dead-letter queue (or failed-jobs table) where it can be inspected and replayed. A failed job that only produces a log line is a lost job.

- Configure max retry attempts on every queue and job type. Unlimited retries turn one poison message into a permanent outage; zero retries turn one network blip into lost work.
- After max retries, move the job to a DLQ with its original payload, the final error, attempt count, and timestamps. Never discard the payload — it is the only thing that makes replay possible.
- Distinguish failure types: retry on transient errors (timeouts, 5xx, deadlocks), dead-letter immediately on permanent ones (validation errors, 4xx, deserialization failures). Retrying a 422 forty times produces forty identical failures, slower.
- Alert on DLQ depth greater than zero. A dead-letter queue nobody watches is a landfill, not a safety net.
- Provide a replay path: a documented command or admin action that re-enqueues DLQ entries after the underlying bug is fixed.
- Never write a consumer whose error handling is only `log(err)` and move on — that acknowledges and destroys the message in most frameworks.

**Red flags that you're about to violate this:**
- "I'll log the error so we can investigate."
- "The job will just be retried by the queue automatically."
- "Failures here are basically impossible, the data is validated upstream."
- "We can add dead-letter handling later once this is working."
- "If it fails, the next scheduled run will pick it up."
- "Catching the exception keeps the worker from crashing, that's enough."

### Separate Readiness From Liveness Checks

ALWAYS expose two distinct health endpoints with distinct meanings. Liveness answers "should this process be restarted?" Readiness answers "should this instance receive traffic right now?" Wiring one endpoint to both questions guarantees a wrong answer to one of them.

- Liveness (`/livez`): checks only the process itself — event loop responsive, not deadlocked. It must NOT check databases, caches, or downstream services. Restarting your process never fixes a dependency, and a liveness probe that checks dependencies converts every dependency blip into a fleet-wide restart loop.
- Readiness (`/readyz`): checks whether this instance can serve real requests — config loaded, migrations verified, connection pools established, critical dependencies reachable. Failing readiness removes the instance from rotation without killing it, and it rejoins automatically when the check passes.
- Only include *hard* dependencies in readiness — ones without which every request fails. A degraded optional dependency (recommendations, email) should degrade responses, not remove instances. If all instances share a failed dependency, readiness pulling all of them is still an outage; consider whether serving errors or serving nothing is worse for that dependency.
- Keep both endpoints fast (sub-second, cached status if needed), unauthenticated from the orchestrator's network, and free of side effects.
- Fail readiness during startup until initialization completes, and during shutdown as the first step of draining — that's what makes rolling deploys zero-downtime.
- Make liveness lenient (high failure threshold) and readiness sensitive. Restarts are expensive and destructive; rotation changes are cheap and reversible.

**Red flags that you're about to violate this:**
- "One /health endpoint is enough, I'll point both probes at it."
- "The health check should verify the database, to be thorough." (In *readiness*. Only readiness.)
- "Return 200 always so the deploy passes."
- "If the dependency is down the pod is useless, might as well restart it."
- "I'll add the downstream API to the check too, we depend on it." (Hard dependency, or nice-to-have?)
- "Probes are an ops concern, I'll leave the defaults."

### Set Timeouts on Every Outbound Service Call

NEVER make an outbound network call without an explicit timeout. Most HTTP clients default to waiting forever, and a hung dependency will consume your threads, connections, or event-loop capacity until your own service falls over.

- Set an explicit timeout on every HTTP call: `requests.get(url, timeout=(3, 10))` in Python, `AbortSignal.timeout(10_000)` with `fetch` in Node, a custom `http.Client{Timeout: 10 * time.Second}` in Go. Never use a client's zero/default timeout without checking what it actually is.
- Cover both phases where the client distinguishes them: connect timeout (short, a few seconds) and read timeout (sized to the dependency's real latency, not "60 to be safe").
- Apply the same rule to gRPC deadlines, database/network drivers, message-broker publishes, DNS-dependent SDK calls, and raw sockets. "Outbound" means anything that leaves the process.
- Size timeouts from the caller's budget: if your handler must answer in 2 seconds, an internal call inside it cannot have a 30-second timeout.
- On timeout, fail the operation deliberately (error, fallback, or retry policy). Do not catch the timeout and silently retry forever, which recreates the hang with extra steps.
- Configure timeouts once at client construction where possible, so new call sites inherit them instead of relying on every author remembering.

**Red flags that you're about to violate this:**
- "The default client settings are fine for this."
- "This internal service is fast, it always responds quickly."
- "Adding timeout parameters clutters the example."
- "If it hangs, the load balancer will deal with it."
- "I'll use a generous 120-second timeout so nothing ever fails."
- "The library probably has a sensible default timeout."

### Stream File Uploads Instead of Buffering in Memory

NEVER read an uploaded file fully into memory. Stream it from the request socket to its destination (object storage, disk, a hashing/scanning pipe) in fixed-size chunks, so memory use per upload is constant regardless of file size.

- Pipe request streams to their destination: multipart streaming parsers (`busboy`/`@fastify/multipart` in Node, `request.stream`/`UploadFile.read(chunk)` in Python, `io.Copy` from `r.Body` in Go) straight into an S3/GCS multipart upload or a temp file. Memory cost: one chunk, not one file.
- Better still, skip your server entirely: issue a presigned URL and let clients upload directly to object storage. Your service handles a small JSON request; the storage provider handles the gigabytes.
- Enforce a maximum body size *before* reading — at the proxy (`client_max_body_size`), the framework limit, or by rejecting on `Content-Length` — and abort mid-stream if a chunked body exceeds the cap. A limit checked after buffering already paid the memory bill.
- Process streamingly too: hash, virus-scan, and validate via stream transforms as bytes pass through. If a step genuinely needs the whole file (image resize), spool to a temp file on disk, and clean it up in a `finally`.
- Validate the type from the first bytes (magic numbers) early so a mislabeled 5GB upload is rejected at chunk one, not chunk last.
- The same applies to downloads and proxying: stream responses out; never load a file into memory just to send it somewhere else.

**Red flags that you're about to violate this:**
- "Files here are small, it's just avatars." (The limit enforcing that is... where?)
- "Reading it into a buffer is so much simpler."
- "I need the whole file to validate it first." (You need the first 16 bytes.)
- "The server has plenty of RAM."
- "I'll base64 it into the JSON payload." (Now it's 33% bigger and buffered twice.)
- "We can optimize for large files later."

### Treat Every Queue as At-Least-Once Delivery

ALWAYS write queue and stream consumers assuming every message can be delivered two or more times, including concurrently to different workers. No broker setting exempts you: crash-before-ack, visibility-timeout expiry, and rebalances all produce duplicates, so duplicate-safety lives in the consumer.

- Give every message a stable unique ID at the producer (entity ID + operation, or a UUID minted once). Random IDs minted at consume time defeat deduplication by definition.
- Make the handler idempotent around that ID: record processed IDs in a store with a uniqueness guarantee (unique index, `INSERT ... ON CONFLICT DO NOTHING`, `SETNX`) and check-or-claim *atomically* before executing side effects. A read-then-write check has a race window exactly when two workers hold the same message.
- Where possible, make the operation naturally idempotent instead of tracking IDs: `SET status = 'shipped'` survives duplicates; `counter = counter + 1` does not.
- Pass the message ID through to downstream effects as an idempotency key (payment APIs, email providers) so retries dedupe end to end.
- Ack only after the work is durably complete. Acking first converts "duplicate" into "lost," which is worse.
- Size the visibility timeout/ack deadline above your worst-case processing time, or extend it via heartbeat — otherwise the broker creates concurrent duplicates on purpose.

**Red flags that you're about to violate this:**
- "The queue is configured for exactly-once delivery."
- "We've never seen a duplicate in this queue."
- "FIFO queues dedupe, so the handler doesn't need to."
- "I'll check if it's processed, then process it." (Not atomically? That's the race.)
- "Processing is fast, the visibility timeout won't expire."
- "Adding idempotency keys is over-engineering for an internal queue."
