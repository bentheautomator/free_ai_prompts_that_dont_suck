---
title: Bound Every In-Process Cache
slug: bound-every-in-process-cache
category: performance
tags: [universal, performance, memory]
works_with: all
severity: critical
one_liner: "Stops unbounded memoization maps that grow until the process runs out of memory"
---

# Bound Every In-Process Cache

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from creating in-memory caches with no size limit, which are memory leaks on a payment plan.

**[Copy-paste ready version](../../install/bound-every-in-process-cache.md)** — just the instruction block, no explanation.

## The Problem

`const cache = new Map()` at module scope, `cache[key] = result` inside the function, and never a single line that removes anything. Or Python's `@functools.lru_cache(maxsize=None)` — the AI reaches for `None` because it saw it in examples and "no limit" sounds like "no problem." Every distinct key ever seen stays in memory until the process dies. In a long-running server, that's not a cache; it's an append-only log of everything the service has ever computed.

The failure is invisible by design. Memory climbs a few megabytes an hour. Tests never run long enough to notice. Local dev restarts constantly. Then three weeks into production the process crosses its memory limit, the OOM killer takes it down mid-request, the orchestrator restarts it, and the sawtooth begins — a slow-motion crash loop that looks like infrastructure flakiness and gets blamed on everything except the `Map` that started it.

The trap snaps shut hardest when the key space is user-controlled: caching by URL, by search query, by request payload hash. The AI pictures a dozen keys; an attacker — or just organic traffic — supplies millions.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

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

---

## Why It Works

1. **It flips the default.** "A bare Map used as a cache is wrong by default" means the AI must justify the unbounded case rather than the bounded one, reversing the burden of proof it normally exploits.
2. **The cardinality question is the actual safety check.** The AI's error is always an unstated "keys are few" assumption; forcing it to name who controls the keys surfaces user-controlled key spaces immediately.
3. **It names the disguises.** `@cache`, `maxsize=None`, and "just memoization" are the specific forms the AI uses while believing it isn't building a cache at all.
4. **The worst-case math in a comment** makes the bound reviewable: a human can veto "1M entries × 2KB" in a way they can never veto an invisible assumption.

## Origin

To avoid recomputing image thumbnail URLs, an assistant memoized the signing function in a process-level dict keyed by the full request path — which included a per-session token, making every key unique. Memory grew about 80MB a day per pod. Eighteen days later the fleet hit container limits within the same hour and the OOM-kill cascade looked exactly like a DDoS. Two engineers spent three days on network forensics before anyone diffed the code and found the dict.
