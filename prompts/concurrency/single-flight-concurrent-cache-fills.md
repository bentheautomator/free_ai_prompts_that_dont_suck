---
title: Single-Flight Concurrent Cache Fills
slug: single-flight-concurrent-cache-fills
category: concurrency
tags: [universal, concurrency, caching]
works_with: all
severity: high
one_liner: "Stops cache-miss stampedes where every concurrent caller recomputes the value"
---

# Single-Flight Concurrent Cache Fills

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from writing caches where every concurrent request that misses goes and computes the value itself, stampeding the expensive backend the cache exists to protect.

**[Copy-paste ready version](../../install/single-flight-concurrent-cache-fills.md)** — just the instruction block, no explanation.

## The Problem

The textbook cache the AI writes: check the cache, on miss compute the value, store it, return it. Correct for one caller. Now expire a hot key under load: two hundred requests arrive in the same 50ms window, all miss, and all two hundred run the expensive query the cache was built to run once. The database — sized for the cache's miss rate, not its absence — takes the spike, slows down, the fills take longer, more requests pile onto the missing key, and a routine TTL expiry becomes a thundering herd that knocks over the backend. The cruel part: the better the cache normally works, the less the backend is provisioned for this, and the harder it falls.

AI assistants write check-compute-store because that *is* a cache, in every tutorial — and with one test request, it's flawless. The missing concept is that a cache under concurrency has three states, not two: hit, miss, and *someone is already fetching this*. The third state never appears in single-caller code, so the AI never writes it. (Note this is a different bug than lazy singleton initialization: not "create one object once per process," but "deduplicate fills per key, forever, under expiry and churn.")

The fix is single-flight: per key, one caller fetches, everyone else awaits the same in-flight result.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Single-Flight Concurrent Cache Fills

A cache fill MUST be deduplicated per key: when callers miss concurrently, exactly one computes the value and the rest await that same computation. Check-compute-store with no in-flight tracking sends every concurrent miss to the backend at once.

A cache without single-flight protects the backend only between expirations, and attacks it at every one.

- In-process: keep a map of in-flight promises/futures per key. On miss, atomically check it — found means await it; absent means insert your promise *before* starting the fetch (insert-then-fetch, or the second caller slips through). Remove the entry when the fill completes.
- Clean up on failure: remove the in-flight entry and decide whether waiters get the error or a retry — but never leave a rejected promise as the permanent answer for the key, and never let a failed fill keep new callers queued behind a corpse.
- Use the built-in where one exists: Go's `singleflight` package, caching libraries with `getOrCompute`/loader semantics that document fill deduplication. Don't hand-roll what the platform provides.
- Cross-instance stampedes (many servers, one Redis, one hot key) need more than in-process tracking: a short-TTL fill lock, probabilistic early refresh, or serving the stale value while one worker revalidates (stale-while-revalidate). Pick one deliberately for genuinely hot keys.
- Expiry policy is part of the fix: refreshing a hot key *before* expiry (background refresh) means concurrent misses never happen on it at all.
- Don't confuse this with lazy init: singletons fill once per process; caches fill per key, repeatedly, under TTL — the dedup must be keyed and must reset after each fill.

**Red flags that you're about to violate this:**
- "Check cache, on miss compute and store — that's just what a cache is."
- "Duplicate fills are wasteful but harmless; same value either way." (Two hundred copies of the same expensive query is the outage.)
- "The TTL is long, misses are rare." (Rare and synchronized: every caller misses at the same moment.)
- "Our load tests passed." (Did one warm the cache first?)
- "I'll lock the whole cache during fills." (Now every key waits on one key's slow fetch.)

---

## Why It Works

1. **It adds the missing third state** — fill-in-flight — which is the structural difference between a cache that absorbs load and one that synchronizes it into spikes.
2. **Insert-promise-before-fetch is the load-bearing ordering:** it closes the same check-then-act gap that otherwise lets a second miss start a second fill, making the dedup atomic rather than advisory.
3. **The failure-cleanup clause prevents the two bad equilibria** of naive implementations: cached errors served forever, or waiters queued behind a fill that already died.
4. **Distinguishing in-process from cross-instance scope keeps the fix honest** — single-flight in one process demonstrably cannot stop a fleet-wide stampede, and the rule says so before production does.

## Origin

A homepage personalization block cached an expensive aggregate with a five-minute TTL. Every five minutes, whatever concurrent traffic existed at that instant — typically a few hundred requests — all missed together and all ran the aggregate. The database graph looked like a heartbeat: flatline, spike, flatline, spike, at perfect five-minute intervals, for months. Everyone read it as "periodic batch job" until someone correlated the spikes with the cache TTL. A twenty-line single-flight wrapper flattened the heartbeat; the aggregate ran once per interval, which is what everyone had assumed the word "cache" already meant.
