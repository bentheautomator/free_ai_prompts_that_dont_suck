---
title: Respect the Read-Write Split
slug: respect-the-read-write-split
category: architecture
tags: [universal, architecture, consistency]
works_with: all
severity: medium
one_liner: "Writes sneaking into query paths in a codebase that separates them"
---

# Respect the Read-Write Split

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from putting writes into the read path — or reads-for-display into the write path — in a codebase that deliberately separates queries from commands.

**[Copy-paste ready version](../../install/respect-the-read-write-split.md)** — just the instruction block, no explanation.

## The Problem

Some codebases separate reads from writes on purpose: query services that only fetch, command handlers that only mutate, sometimes different models or even different databases for each side (CQRS, read replicas, denormalized view tables). The separation carries guarantees — queries are safe to call anywhere, retry, cache, and point at replicas; commands carry the validation, events, and audit trail. Then the AI gets a task like "track when a profile was last viewed," and the cheapest diff is an `UPDATE last_viewed_at` inside `ProfileQueryService.get_profile()`. One line. The read side now writes.

Every guarantee breaks at once. The query was served from a read replica, so the write either fails or silently goes nowhere depending on the driver. A caching layer in front of the query service means views stop being tracked whenever the cache hits. Retried reads double-write. And the next engineer, who calls query methods freely *because queries are safe* — that's the whole deal — triggers mutations they cannot see. The reverse direction fails too: command handlers that start returning rich query data grow into the API's de facto read path, and now the read model's denormalized views are bypassed in some flows and authoritative in others.

The AI does this because the split is invisible in any single file. `get_profile()` has a database handle; nothing about the method's body says "this connection is a replica" or "this result is cached upstream." The architecture's rules live in the directory names, and the AI didn't read them as rules.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Respect the Read-Write Split

If the codebase separates reads from writes — query services vs. command handlers, read models vs. write models, replicas vs. primary — NEVER put a mutation in the read path or build a new read flow against the write model. Work within the side your task belongs to, even when crossing would be a smaller diff.

The split's value is its guarantees: reads are cacheable, retryable, replica-safe, and side-effect-free precisely because nothing ever writes there. One exception deletes the guarantee for every caller.

- Before touching a method, determine which side it's on: naming (`*QueryService`, `*ReadModel`, `commands/`, `queries/`), the database handle it uses, and what its siblings do. Then stay on that side
- A task that needs both ("show the profile AND record the view") is two operations: the query stays pure, and the write goes through a command — dispatched by the caller or handler, not smuggled into the getter
- Don't read your own writes through the read model immediately after a command if the read side is eventually consistent (replicas, projections); return what the command knows, or read from the write side within that flow if the codebase has a pattern for it
- New display/listing/reporting features go against the read side, even if the write model technically has the data — bypassing the read model forks the codebase's answer to "where do reads come from"
- If the task genuinely requires changing what the read model contains, that's a projection/view change on the read side, not a write-side query bolted on
- No split in this codebase? Then this rule is dormant — don't introduce CQRS to follow it

**Red flags that you're about to violate this:**
- "It's just a timestamp update, the query method already has the row..."
- "Adding a whole command for this tiny write is ceremony..."
- "The write model has all the fields, I'll query it directly..."
- "One side effect in a getter won't hurt anything..."
- "I'll read it back right after writing, it's the same database... probably..."

---

## Why It Works

1. **It ties the rule to the guarantees, not the dogma.** "Reads are safe to call anywhere" is a property every caller already relies on; framing mutation-in-a-getter as deleting that property makes the one-line diff legibly expensive.

2. **It gives the two-operation decomposition.** Most violations come from tasks that straddle the split; "the query stays pure, the caller dispatches the command" is the standard shape the AI can apply without inventing one.

3. **It names the consistency trap.** Read-after-write against an eventually consistent read side is the bug that *passes locally* (one database in dev) and fails in production (replicas); calling it out moves the check to write time.

4. **It scopes itself honestly.** Declaring the rule dormant in codebases without a split prevents the worst outcome — an AI installing CQRS in a CRUD app to comply.

## Origin

A marketplace tracked listing views with an update inside the listing query service. In production, queries ran against read replicas; the driver silently dropped writes on the replica connection, so view counts crept up only via the fraction of traffic that hit the primary. Sellers' analytics showed roughly a tenth of real views for five months — discovered only when a seller compared their numbers against their own server logs and filed a support ticket titled "your analytics are off by 10x." The fix was a view-recorded command dispatched from the handler: four lines, on the correct side of the line.
