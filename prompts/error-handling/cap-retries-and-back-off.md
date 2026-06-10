---
title: Cap Retries and Back Off
slug: cap-retries-and-back-off
category: error-handling
tags: [universal, errors, retries]
works_with: all
severity: high
one_liner: "AI writing unbounded retry loops that hammer failing services forever"
---

# Cap Retries and Back Off

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents while-true retry loops with no attempt limit, no backoff, and no exit plan.

**[Copy-paste ready version](../../install/cap-retries-and-back-off.md)** — just the instruction block, no explanation.

## The Problem

"Keep trying until it works" gets implemented literally: `while True: try: connect(); break; except: time.sleep(1)`. When the target service goes down for an hour, this loop sends 3,600 connection attempts, holds its thread hostage the entire time, and gives the recovering service a steady drumbeat of load exactly when it's weakest. With many clients running the same loop, the retries synchronize into waves — the classic thundering herd — and the service that just came back up gets knocked over again by its own clients.

A subtler variant hides the same bug: recursion. `function fetchWithRetry() { return fetch(url).catch(() => fetchWithRetry()); }` retries forever *and* grows a promise chain. Or the retry has a count but no delay — five attempts in four milliseconds, which is five chances to hit the same in-flight failure, not five chances spread across a recovery window.

Assistants write unbounded retries because "until it succeeds" sounds like persistence and persistence sounds like reliability. The questions a retry loop actually has to answer — how many attempts, spaced how, and *then what* — don't appear in the happy-path mental model, so they don't appear in the code.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Cap Retries and Back Off

Every retry loop MUST have three things: a maximum attempt count, exponential backoff with jitter, and a defined behavior for when attempts run out. NEVER write `while True` around a failing operation.

An unbounded or undelayed retry loop is a denial-of-service tool pointed at a service that is already struggling — and at your own thread pool.

- Cap attempts at a small explicit number (typically 3–5) chosen for the operation, not infinity by omission
- Space attempts with exponential backoff plus jitter: e.g. `delay = min(base * 2**attempt, max_delay) * random.uniform(0.5, 1.5)` — fixed 1-second sleeps synchronize clients into thundering herds
- Decide and implement what happens after the final attempt: raise the last error, return an explicit failure, enqueue for later — "loop forever" is not a final-attempt policy
- Immediate re-attempts with no delay are not retries; they are the same failure sampled five times in the same instant
- Bound the *total* time as well as the attempt count when the caller has a deadline (request handlers, anything holding a lock or connection)
- Prefer the project's existing retry utility or library (tenacity, retry middleware, urllib3 `Retry`) over a hand-rolled loop; if hand-rolling, all three elements must still be present

**Red flags that you're about to violate this:**
- "It should keep trying until the service comes back..."
- "A simple while loop with a sleep is good enough here..."
- "I'll have it call itself again on failure..."
- "Retrying immediately gives the fastest recovery..."
- "We never expect it to fail more than once or twice anyway..."

---

## Why It Works

1. **The three-element checklist is mechanically verifiable.** Cap, backoff-with-jitter, exhaustion behavior — the model can scan its own loop for all three before emitting it, which a vague "retry responsibly" doesn't enable.

2. **It forces the exhaustion question.** The entire reason unbounded loops exist is that "what happens when retries run out" was never asked. Making that answer a required component of the code makes the infinite loop impossible to write by accident.

3. **It explains jitter's purpose, not just its presence.** Models drop jitter because it looks like noise. Tying fixed delays to synchronized client herds gives the randomness a reason the model can preserve under refactoring.

4. **It reframes persistence as aggression.** "Keep trying" reads as diligence; naming the retry loop as load directed at a struggling dependency flips the moral framing that generates the pattern.

## Origin

A worker service got AI-written "resilient" startup code: loop forever until the message broker accepts a connection, retrying every 500ms. During a broker upgrade, 200 worker pods entered the loop simultaneously — 400 connection attempts per second, perfectly synchronized. The broker came up, drowned in the reconnection storm, failed its health check, and restarted, in a cycle that repeated for 40 minutes until someone scaled the workers to zero by hand. The fix was eight lines: a cap, exponential backoff, and jitter.
