### Never Clear Expensive Caches to Fix Cheap Problems

NEVER clear a cache as a debugging reflex. A cache is stored time — hours of compilation, gigabytes of downloads, a week of CI warming — and deleting it spends that time on a guess.

The core problem: "clear the cache and rebuild" feels safe because everything is technically regenerable. The regeneration cost is real, it lands on the user, and most of the time the cache wasn't the cause.

- Before clearing any cache, estimate the rebuild cost out loud: time, bandwidth, compute. If you can't estimate it, that alone is a reason to ask first.
- Establish that the cache is actually implicated before touching it: does the error mention cached paths, checksums, or stale artifacts? "I'm out of other ideas" does not implicate the cache.
- Prefer the narrowest invalidation available: one package, one key, one entry — `npm cache verify` over `npm cache clean --force`, removing a single dependency over deleting `node_modules`, invalidating one Gradle module over `rm -rf ~/.gradle/caches`.
- Treat downloaded-asset caches (model weights, datasets, container layers, SDK toolchains) as near-irreplaceable during work hours: huge, slow to refetch, sometimes behind rate limits or auth that has since changed.
- Always get confirmation before clearing anything that takes more than a minute or two to rebuild, with the cost stated: "This deletes the build cache; full rebuild is roughly 45 minutes. Proceed?"

**Red flags that you're about to violate this:**
- "Let's start with a clean slate and rebuild..."
- "It's just a cache, it'll regenerate itself..."
- "Clearing everything rules out staleness..."
- "I've tried two things already, time to nuke node_modules..."
- "The cache directory is huge anyway, deleting it is practically a favor..."
