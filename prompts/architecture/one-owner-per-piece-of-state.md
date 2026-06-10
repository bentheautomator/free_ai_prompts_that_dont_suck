---
title: One Owner Per Piece of State
slug: one-owner-per-piece-of-state
category: architecture
tags: [universal, architecture, state]
works_with: all
severity: critical
one_liner: "Two modules both writing the same state until neither knows what's true"
---

# One Owner Per Piece of State

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from giving a second module write access to state that another module already owns, creating two sources of truth that will disagree.

**[Copy-paste ready version](../../install/one-owner-per-piece-of-state.md)** — just the instruction block, no explanation.

## The Problem

The task says "mark the order as shipped when the label prints." The `orders` module owns order status — it has the transition rules, the audit logging, the notification triggers. But the AI is editing the `shipping` module, the database client is right there, and `UPDATE orders SET status = 'shipped'` is one line. So shipping starts writing order status directly. Now two modules both believe they own that column: one enforces the state machine, the other bypasses it.

The damage is not hypothetical and not gradual. The second writer skips whatever the first writer's invariants are — validations, side effects, cache invalidation, event emission — because it doesn't know they exist. Orders go to "shipped" without the customer email firing. A status cache in `orders` is now stale because the write didn't pass through it. And debugging is brutal, because everyone investigating starts from the reasonable assumption that order status changes go through the orders module.

AI assistants create second writers constantly because write access is rarely enforced. The table is reachable, the field is public, the in-memory store is importable. Ownership in most codebases is a convention held in people's heads, and the AI wasn't in the meeting.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### One Owner Per Piece of State

NEVER write to state that another module owns. Every table, field, cache, file, or store has exactly one owning module; everyone else reads through its interface and requests changes through its functions.

A second writer bypasses every invariant the owner enforces — validations, transitions, side effects, cache coherence — and creates bugs that only reproduce depending on who wrote last.

- Before writing to any shared state, find who else writes it: grep for updates to that table/field/key. If another module is the established writer, call its function instead of writing directly
- If the owner doesn't expose the operation you need (e.g., no `mark_shipped()`), ADD that function to the owner — that's a smaller change than a second writer, even though it touches another module
- Direct `UPDATE`/`SET` from outside the owning module is a bypass even when the SQL is correct, because the owner's side effects (events, audit rows, cache busts) don't fire
- This applies to in-memory state too: don't mutate another module's exported dict, store, or cached object; call its mutator
- If ownership is genuinely ambiguous (two modules already write it), don't silently become the third — flag the conflict in your summary

**Red flags that you're about to violate this:**
- "It's just one UPDATE, going through the orders module is overkill..."
- "The owning module doesn't have a function for this, so I'll write directly..."
- "Adding a method to their module is out of my task's scope..."
- "I'm setting the same value their code would set anyway..."
- "The field is public/the table is shared, so writing it is allowed..."

---

## Why It Works

1. **It makes ownership discoverable instead of tribal.** "Grep for who else writes this" turns an unwritten convention into a 30-second check the AI can actually perform.

2. **It names the real cost: skipped invariants.** The second write looks identical to the first in the database; the rule explains that the difference is everything that *didn't* happen — which is why "same value anyway" is wrong.

3. **It authorizes the cross-module edit.** The honest fix (add `mark_shipped()` to the owner) feels like scope creep, so the AI avoids it; explicitly blessing it removes the incentive to take the bypass.

4. **It scales from databases to dicts.** Dual ownership is the same bug at every storage tier; covering in-memory state stops the rule from being read as "a SQL thing."

## Origin

A fulfillment service began setting order status directly because the orders module "didn't have the right method." The direct write skipped event emission, so the analytics pipeline — fed by those events — silently stopped counting a fraction of shipments. Finance noticed a revenue/shipment mismatch two quarters later, and the investigation took three weeks precisely because everyone audited the orders module first: the code that owned the state was correct, and the bug lived in the module that had decided not to use it.
