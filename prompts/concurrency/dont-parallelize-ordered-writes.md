---
title: Don't Parallelize Ordered Writes
slug: dont-parallelize-ordered-writes
category: concurrency
tags: [universal, concurrency, ordering]
works_with: all
severity: critical
one_liner: "Stops gather/Promise.all on operations whose order actually matters"
---

# Don't Parallelize Ordered Writes

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from throwing order-dependent operations into `Promise.all` or a goroutine fan-out, so steps that must happen in sequence race each other instead.

**[Copy-paste ready version](../../install/dont-parallelize-ordered-writes.md)** — just the instruction block, no explanation.

## The Problem

Ask an AI to "speed this up" and it reaches for `Promise.all` like a hammer. Sometimes the nails are actually screws: create the parent record and its children, debit one account and credit another, write the file and then update the index that points at it. Run those concurrently and most of the time it works, because the first operation usually finishes first anyway. Then one day the child insert lands before the parent exists, the index points at a file still being written, or a downstream consumer sees the credit without the debit. The bug fires on a timing distribution, not a code path, so it reproduces roughly never on a laptop and roughly weekly in production.

The AI does this because the dependency between two writes is rarely visible in the code. `createParent(p)` and `createChild(c)` look like sibling calls; the fact that one must complete before the other starts lives in the database schema, the consumer's assumptions, or the filesystem, none of which the AI is looking at when it refactors for speed. The sequential version it's "improving" was often sequential *on purpose*, with the purpose written down nowhere.

This is the mirror image of failing to parallelize independent awaits, and it's the worse direction to be wrong in: sequential-when-parallel-was-fine costs milliseconds; parallel-when-sequential-was-required costs data.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Don't Parallelize Ordered Writes

NEVER make sequential operations concurrent without first proving they are order-independent. Treat existing sequence as a claim about ordering until you've shown otherwise; absence of a comment is not absence of a dependency.

Parallelizing dependent writes replaces a deterministic order with a coin flip that lands wrong only under production timing.

- Before moving anything into `Promise.all` / `asyncio.gather` / a goroutine fan-out, check each pair: does B read, reference, or assume the effects of A? Foreign keys, file-then-index, debit-then-credit, create-then-notify are all hard orderings.
- Reads of independent data may overlap freely. Writes may overlap only when they touch disjoint state *and* no observer assumes an order between them.
- Mixed batches are a trap: parallelizing three reads and one write puts the write at a random position among the reads. Keep the write sequenced.
- "It must happen after" includes external observers: if a webhook, queue consumer, or user can see B's effect, A must already be visible by then.
- If order matters for some pairs and not others, parallelize within stages and sequence the stages: `await Promise.all(reads); await write;`
- When you genuinely can't tell whether order matters, keep it sequential and say so. Slow and right beats fast and intermittently corrupt.

**Red flags that you're about to violate this:**
- "These can obviously run in parallel, they're separate calls."
- "I ran it five times and the order came out fine."
- "The original author probably just didn't think to parallelize."
- "The database will sort out the ordering."
- "It's only a notification/index/cache update, order can't matter."

---

## Why It Works

1. **It inverts the burden of proof.** The AI's default is "parallel unless someone objects"; the rule makes it "sequential until independence is demonstrated," which matches where the asymmetric risk is.
2. **It defines "depends on" broadly enough to catch the real cases** (schemas, observers, consumers), not just data flow visible in the local function.
3. **It legalizes staged parallelism,** so the AI doesn't treat the rule as "never use gather" and lose the wins that are actually safe.
4. **Five clean runs sample one scheduler mood.** The rule replaces empirical reassurance with a dependency argument, which is the only evidence that covers all interleavings.

## Origin

A batch importer was "optimized" by gathering the order insert and the order-event publish concurrently. The event consumer looked up the order on receipt. In staging, inserts always won the race. In production, under load, the publish occasionally arrived first, the consumer found no order, logged "skipping unknown order," and acked the message. Roughly forty orders a week silently never entered fulfillment, and it took a customer-support pattern, not a single alert, to notice the optimization had been shipping coin flips.
