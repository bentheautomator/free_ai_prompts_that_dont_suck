### Size Defaults for Production, Not the Demo

When choosing a default for any capacity, limit, or rate config, ALWAYS ask: what does this value do at production load, during a downstream outage, on the biggest tenant? The default is what production will run, because most deployments never override most keys.

"Works in dev" is the weakest possible evidence about a default — dev traffic can't punish a bad one.

- Anything that accumulates gets a bound by default: caches, queues, buffers, batch sizes, in-flight request counts. Unbounded is not a default; it's an outage with patience. If a bound feels arbitrary, a generous explicit bound still beats none.
- Anything that retries gets a cap and backoff by default: max attempts, max total time, jitter. Default-infinite retries are a self-inflicted DDoS waiting for a downstream blip.
- Anything that accepts input gets a size limit by default: request bodies, uploads, line lengths, array counts.
- Pools and concurrency sized for "my machine" are not defaults — if the right value depends on the deployment, make the key required (fail at startup when unset) instead of guessing small.
- Don't weaken an existing safety default to make dev pleasant. Loosen it in the dev overlay; the shared default stays production-safe.
- State your reasoning when you pick a default: "default 10MB body limit; raise per-environment if needed" is a decision someone can review. A bare number is not.

**Red flags that you're about to violate this:**
- "Unlimited is fine, the cache never gets big."
- "I tested it and memory usage was tiny."
- "Production will obviously override this."
- "A limit might break someone's legitimate use case, so no limit."
- "Four workers handled all my test load."
- "Retry forever — it should be resilient."
