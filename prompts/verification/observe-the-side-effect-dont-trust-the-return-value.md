---
title: Observe the Side Effect Don't Trust the Return Value
slug: observe-the-side-effect-dont-trust-the-return-value
category: verification
tags: [universal, verification, state]
works_with: all
severity: high
one_liner: "Claiming a write, send, or delete happened because the call returned success"
---

# Observe the Side Effect Don't Trust the Return Value

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the assistant from claiming a state change happened based on the operation's return value instead of the state itself.

**[Copy-paste ready version](../../install/observe-the-side-effect-dont-trust-the-return-value.md)** — just the instruction block, no explanation.

## The Problem

The operation said it worked, so the assistant reports the world changed: "record created," "email queued," "file uploaded," "cache invalidated." But return values describe the operation's opinion of itself, and operations are unreliable narrators. The insert succeeded — inside a transaction that later rolled back. The upload returned success — to a mock endpoint left over from testing. The save call completed — writing to a path nobody reads. The delete returned fine — matching zero records. Each return value was truthful about what the operation did and silent about whether the intended state change exists.

Assistants stop at the return value because it arrives in-band, immediately, addressed to them. Checking the actual state means a second act — select the row back, list the bucket, read the queue depth — directed at a different system, after the fact. The return value feels like the receipt; it's actually the cashier saying "that probably went through."

The claims this produces are about durable state — data saved, message sent, resource gone — which is exactly what users build on. A "record created" that wasn't becomes a missing order; a "cache invalidated" that wasn't becomes a week of users seeing stale prices while everyone trusts the code because the call "succeeded."

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Observe the Side Effect Don't Trust the Return Value

NEVER claim a state change happened — row written, file created, message sent, resource deleted — on the strength of the operation's return value. Verify by observing the state itself, through a separate read.

The core problem: a return value is the operation reporting on the operation. Rolled-back transactions, mocked endpoints, wrong targets, zero-match deletes, and fire-and-forget queues all return success while leaving the world unchanged.

- After a write you're about to claim, read it back through an independent path: select the row, stat the file, fetch the object, check the queue depth or the recipient side. The read must not share the failure mode of the write (re-reading your own in-memory object proves nothing).
- For deletes and invalidations, verify absence: the query returns nothing, the key misses, the resource 404s. "Delete returned success" with zero rows matched is a no-op wearing a medal.
- Within transactions, verification counts only after commit. A read inside the same uncommitted transaction will happily show you data that's about to vanish.
- For async effects (queues, webhooks, eventual writes), "accepted" is the claim the return value supports. The effect happened when you observe it happened — poll the destination or report "enqueued, delivery unconfirmed."
- Verify the operation hit the intended target: right database, right bucket, right environment. Success against the wrong target is the cruelest variant, and only the read-back exposes it.
- Make the claim match the observation: "inserted and selected back row id 4821" rather than "saved successfully."

**Red flags that you're about to violate this:**
- "The call returned 201, so the record exists..."
- "The library would have thrown if the write failed..."
- "Reading it back is a redundant round trip..."
- "Delete succeeded — no need to count what it deleted..."
- "The queue accepted it; sending is its problem now..."
- "I checked the object in memory and it has the saved data..."

---

## Why It Works

1. **It names the unreliable narrator.** "The return value is the operation reporting on the operation" makes vivid why in-band success can't certify out-of-band state — collapsing the trust the model places in it by default.

2. **It requires path independence.** Specifying that the read-back must not share the write's failure mode blocks the pseudo-checks (same transaction, same in-memory object) that feel like verification and verify nothing.

3. **It handles absence and async explicitly.** Deletes and queued sends are where the loopholes live; giving each its own verification shape (observe absence; poll the destination or downgrade the claim) leaves no claim type uncovered.

4. **It binds wording to the read.** "Inserted and selected back row id 4821" is only writable post-observation — the report format enforces the behavior.

## Origin

An assistant built a signup flow and verified it end to end: the API returned 201, the welcome email call returned accepted, the report said "users are created and welcomed." The signup handler's transaction rolled back on a constraint violation in a later step — after the email call had already fired. For two days, new users received warm welcome emails for accounts that did not exist, then couldn't log in. One `SELECT` by email address, run during the original session, would have revealed a table that gained no rows all afternoon.
