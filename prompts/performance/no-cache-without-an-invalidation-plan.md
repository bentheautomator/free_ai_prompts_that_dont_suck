---
title: No Cache Without an Invalidation Plan
slug: no-cache-without-an-invalidation-plan
category: performance
tags: [universal, performance, caching]
works_with: all
severity: high
one_liner: "Stops caches added with no answer for when entries become wrong"
---

# No Cache Without an Invalidation Plan

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from bolting a cache onto slow code without deciding how cached entries get updated or expired when the underlying data changes.

**[Copy-paste ready version](../../install/no-cache-without-an-invalidation-plan.md)** — just the instruction block, no explanation.

## The Problem

When an AI assistant decides something is slow, its favorite move is wrapping it in a cache: a `@lru_cache` decorator, a module-level `Map`, a Redis `SET` with no TTL. The write path is five lines and the demo gets visibly faster, so it feels like a pure win. The question the AI never asks is the only one that matters: when this data changes, how does the cache find out?

Without an answer, the cache is a staleness machine. The user updates their profile and the old name renders for hours. A price change doesn't take effect. A revoked permission keeps working — which is the moment a performance shortcut becomes a security incident. Worse, these bugs are intermittent and environment-dependent: they vanish on restart, never reproduce locally, and burn days of debugging because nobody suspects the innocent-looking decorator added three months ago.

Assistants do this because caching is the canonical "make it fast" pattern in training data, and because the insertion is local while invalidation is global — it requires knowing every code path that mutates the data, which the AI hasn't looked for. So it ships the half of the feature that's easy and silently skips the half that's correctness.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

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

---

## Why It Works

1. **It reframes the artifact.** "A staleness bug with good latency" recasts the AI's favorite optimization as a defect class, which changes what "done" means for the change.
2. **It makes invalidation a deliverable, not a follow-up.** Requiring it in the same change kills the "later" rationalization that, in practice, means never.
3. **The write-path audit forces the global view.** The AI's failure is local reasoning; demanding an enumeration of mutation sites makes the missing work visible and undeniable.
4. **Key correctness is called out separately** because it's the variant that turns a staleness bug into a data leak, and the AI won't think of it under the heading "invalidation."

## Origin

Asked to speed up a permissions check, an assistant cached the user-to-roles lookup in process memory with no TTL and no invalidation. Revoking access then did nothing until the next deploy restarted the pods. A contractor whose access was pulled on a Friday retained admin rights all weekend, which was discovered during the following quarter's access review and reclassified the "performance tweak" as a security finding.
