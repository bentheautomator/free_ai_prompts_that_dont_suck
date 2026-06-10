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
