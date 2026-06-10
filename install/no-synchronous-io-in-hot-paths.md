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
