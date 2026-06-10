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
