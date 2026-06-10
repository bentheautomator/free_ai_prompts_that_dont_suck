---
title: No Sleeps to Fix Race Conditions
slug: no-sleeps-to-fix-race-conditions
category: debugging
tags: [universal, debugging, root-cause]
works_with: all
severity: critical
one_liner: "AI papering over race conditions with setTimeout(100) and sleep(1)"
---

# No Sleeps to Fix Race Conditions

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from "fixing" ordering and timing bugs by inserting sleeps that make the race lose less often.

**[Copy-paste ready version](../../install/no-sleeps-to-fix-race-conditions.md)** — just the instruction block, no explanation.

## The Problem

`setTimeout(() => check(), 100)`. `await sleep(500); // give the db time to settle`. `time.sleep(1)  # wait for the worker`. When code fails because two things happen in the wrong order, the AI's favorite move is to make one of them slower and call it fixed. And it *looks* fixed — on this machine, at this load, today. A sleep doesn't remove a race condition; it changes the odds. The bug is still there, waiting for a slow CI runner, a cold cache, or a customer on a loaded box.

The reason this pattern is so seductive is that it works immediately and requires zero understanding. Finding the real fix means identifying what event the code is actually waiting for — a promise to resolve, a row to commit, a message to be consumed — and synchronizing on *that*. That requires reading the concurrency structure. A sleep requires typing one line.

These are among the most expensive bugs an assistant can plant, because they pass review (one innocuous line), pass tests (usually), and detonate probabilistically in production where they're nearly impossible to trace back to "the AI added a 100ms delay eight months ago."

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No Sleeps to Fix Race Conditions

NEVER fix an ordering, timing, or race bug by inserting a sleep, delay, or arbitrary timeout. A sleep changes the probability of the race; it does not remove the race.

If code fails because event B ran before event A finished, the fix is to synchronize on A's actual completion, not to make B late.

- Identify the concrete event being waited for: a promise/future resolving, a transaction committing, a message acked, a file flushed, an element rendered, a service reporting ready
- Synchronize on that event directly: `await` the operation, use a callback/completion signal, a lock, a condition variable, a readiness probe, a join
- If the system genuinely offers no completion signal, poll *for the condition itself* with a bounded retry and a clear failure, never a single blind delay
- Treat any number you'd have to choose (100ms? 500ms? 2s?) as proof you're guessing; correct synchronization has no magic number to tune
- If you find an existing sleep masking a race while debugging, flag it as a bug, don't tune it upward
- In tests, the same rule applies: wait for the observable condition, not the clock

**Red flags that you're about to violate this:**
- "A small delay here should give the async operation time to complete..."
- "Bumping this from 100ms to 500ms makes it pass consistently..."
- "It's just a test, a sleep is fine here..."
- "The race is rare; the delay makes it effectively impossible..."
- "There's no clean way to know when it's done, so I'll wait a bit..."
- Choosing a duration by trying values until the failure stops

---

## Why It Works

1. **It reframes what a sleep does.** The model treats "no longer fails" as "fixed." Stating that a sleep only shifts the probability distribution breaks the equivalence the rationalization depends on.

2. **It names the real fix as a findable object.** "Synchronize on the actual completion event" turns a vague design demand into a concrete search task — find the promise, the ack, the signal — which the AI is good at once pointed there.

3. **It uses the magic number as a tripwire.** Any duration you must pick is self-evidently a guess about hardware and load. Making the number itself the red flag catches the pattern even in disguises like "grace period" or "settle time."

4. **It covers the tuning variant.** Half of these incidents are not new sleeps but existing ones being raised; the instruction explicitly closes that door.

## Origin

A checkout flow intermittently charged customers without creating an order record. The assistant diagnosed "the order service is sometimes slow" and inserted a 300ms delay before the confirmation step. The failure rate dropped from daily to monthly — low enough that everyone moved on, and rare enough that each occurrence cost a support escalation and a manual refund. The real fix, made after a particularly bad weekend, was a four-line change: await the order-write acknowledgment instead of assuming it. The sleep had bought six months of slow-motion damage.
