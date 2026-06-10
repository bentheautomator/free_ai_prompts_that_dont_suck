---
title: Add Jitter and Backoff to Every Retry
slug: add-jitter-and-backoff-to-every-retry
category: backend
tags: [universal, backend, reliability]
works_with: all
severity: critical
one_liner: "Keeps synchronized retries from finishing off a recovering dependency"
---

# Add Jitter and Backoff to Every Retry

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents naive retry loops from turning a dependency's bad minute into a self-sustaining retry storm that keeps it down.

**[Copy-paste ready version](../../install/add-jitter-and-backoff-to-every-retry.md)** — just the instruction block, no explanation.

## The Problem

The retry logic an assistant writes by default looks like this: try, catch, sleep one second, try again, three times. Sometimes it skips the sleep. Each caller in isolation looks harmless. The problem is that failures are correlated: when a dependency stumbles, *all* of its callers fail at the same moment, all start their identical retry schedules at the same moment, and all retry in synchronized waves — at one second, at two, at three. The dependency, already struggling, now receives its normal load multiplied by every retry layer, arriving in coordinated pulses.

This is how a 30-second blip becomes a three-hour outage. The dependency starts to recover, the synchronized wave hits, it falls over again, the wave re-synchronizes. Stack three layers of retries (client retries × service retries × SDK internal retries, 3 each) and a single user action becomes 27 requests. The mechanism even has a name — retry storm, thundering herd — and it features in approximately every large-scale postmortem ever published.

Assistants write naive retries because in dev, a retry is one client politely re-asking one healthy server. The storm requires a thousand callers failing simultaneously, which is precisely the condition no development environment ever produces.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Add Jitter and Backoff to Every Retry

NEVER retry immediately or on a fixed interval. Every retry policy MUST use exponential backoff with randomized jitter and a retry budget. Failures are correlated — when a dependency breaks, all callers fail together, and unjittered retries form synchronized waves that keep the dependency down.

- Use exponential backoff with full jitter: `sleep(random(0, min(cap, base * 2^attempt)))`. The randomness is not optional garnish — it is the mechanism that decorrelates callers; exponential backoff alone still produces (spreading) waves.
- Cap total attempts (typically 2–4) and cap total elapsed time against the caller's deadline. Retrying past the point where anyone is still waiting for the answer is pure load, zero value.
- Retry only what can plausibly succeed on retry: timeouts, 5xx, connection resets, broker redelivery hints. Never retry 4xx (except 429), validation failures, or non-idempotent operations that may have partially succeeded — see your idempotency rules first.
- Honor `Retry-After` on 429/503 over your own schedule. The server is telling you its actual recovery plan.
- Count your layers: if the SDK retries 3x, your service retries 3x, and the client retries 3x, one failure costs 27 requests. Pick one layer to own retries (usually the lowest one with idempotency context) and make the others fail fast.
- For high-traffic paths, add a circuit breaker or retry-budget (e.g., retries may be at most 10% of requests) so a hard-down dependency gets near-zero traffic instead of maximum traffic.

**Red flags that you're about to violate this:**
- "I'll just retry after a one-second sleep."
- "Jitter is overkill for an internal service."
- "More retries means more reliability." (Means more load on whatever is already failing.)
- "Retry until it succeeds."
- "The SDK probably doesn't retry on its own." (Check. It does.)
- "It's fine, the dependency can handle a few extra requests." (Times every caller. In sync.)

---

## Why It Works

1. **It targets correlation, the part assistants can't see.** A single retrying client is harmless; the rule injects the fleet-wide view where thousands of clients fail and retry as one. Jitter is what breaks that synchronization — naming it as the mechanism stops it being dropped as a nicety.
2. **It bounds the multiplication.** Layer-counting and budgets convert retry amplification from an unbounded product into a known constant, which is the difference between "elevated load" and "27x stampede."
3. **It aligns retries with someone still listening.** Tying retry duration to the caller's deadline eliminates the most wasteful traffic class: retries for answers nobody will ever read.
4. **It distinguishes recoverable from deterministic failures.** Retrying a 400 forever isn't resilience, it's a tight loop with a sleep in it; the classification step removes that entire bug family.

## Origin

An internal pricing service had a four-second brownout during a deploy. Three layers of fixed-interval retries — frontend, gateway, and an SDK nobody knew retried — multiplied its normal load roughly twentyfold in synchronized two-second waves. Every time the service got a pod healthy, the next wave knocked it down. Total outage: just under three hours, for a deploy blip that should have cost four seconds. The remediation PR was eleven lines, most of them a `random()` call.
