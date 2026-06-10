---
title: Set Timeouts on Every Outbound Service Call
slug: set-timeouts-on-every-outbound-service-call
category: backend
tags: [universal, backend]
works_with: all
severity: critical
one_liner: "Stops one slow dependency from hanging every thread in your service"
---

# Set Timeouts on Every Outbound Service Call

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents outbound HTTP, gRPC, and socket calls with no timeout from hanging your service when a dependency stalls.

**[Copy-paste ready version](../../install/set-timeouts-on-every-outbound-service-call.md)** — just the instruction block, no explanation.

## The Problem

`requests.get(url)`, `fetch(url)`, `http.Get(url)` — every one of these waits forever by default, and every one of these is what an AI assistant writes when you ask it to call another service. Python's `requests` has no default timeout. Node's `fetch` will happily sit on a half-open connection. Go's `http.DefaultClient` has `Timeout: 0`, which means never. The assistant writes the call, it returns in 40ms against a healthy dev dependency, and the code ships.

Then the dependency has a bad day. It doesn't fail — failing would be fine, you'd get an exception — it just gets slow, or stops responding mid-handshake. Every request into your service that touches that call now occupies a thread, a connection, or an event-loop task indefinitely. Within minutes your worker pool is full of requests waiting on a service that will never answer, and your service is down because someone else's service is slow. That's the textbook cascading failure, and the root cause is a missing keyword argument.

Assistants skip timeouts because nothing in dev ever hangs. The happy path is indistinguishable from the correct code right up until the first dependency brownout.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Set Timeouts on Every Outbound Service Call

NEVER make an outbound network call without an explicit timeout. Most HTTP clients default to waiting forever, and a hung dependency will consume your threads, connections, or event-loop capacity until your own service falls over.

- Set an explicit timeout on every HTTP call: `requests.get(url, timeout=(3, 10))` in Python, `AbortSignal.timeout(10_000)` with `fetch` in Node, a custom `http.Client{Timeout: 10 * time.Second}` in Go. Never use a client's zero/default timeout without checking what it actually is.
- Cover both phases where the client distinguishes them: connect timeout (short, a few seconds) and read timeout (sized to the dependency's real latency, not "60 to be safe").
- Apply the same rule to gRPC deadlines, database/network drivers, message-broker publishes, DNS-dependent SDK calls, and raw sockets. "Outbound" means anything that leaves the process.
- Size timeouts from the caller's budget: if your handler must answer in 2 seconds, an internal call inside it cannot have a 30-second timeout.
- On timeout, fail the operation deliberately (error, fallback, or retry policy). Do not catch the timeout and silently retry forever, which recreates the hang with extra steps.
- Configure timeouts once at client construction where possible, so new call sites inherit them instead of relying on every author remembering.

**Red flags that you're about to violate this:**
- "The default client settings are fine for this."
- "This internal service is fast, it always responds quickly."
- "Adding timeout parameters clutters the example."
- "If it hangs, the load balancer will deal with it."
- "I'll use a generous 120-second timeout so nothing ever fails."
- "The library probably has a sensible default timeout."

---

## Why It Works

1. **It corrects a false belief about defaults.** Assistants assume mature HTTP libraries default to something sane. Naming the actual defaults — `requests` waits forever, Go's `DefaultClient` waits forever — removes the "the library probably handles it" assumption that produces the bug.
2. **It reframes the failure as slowness, not errors.** The assistant codes for the dependency returning an error, which dev exercises constantly. Stating that the dangerous mode is a dependency that *never answers* forces handling of a case dev never produces.
3. **It closes the "huge timeout" loophole.** A 120-second timeout passes a literal reading of "set a timeout" while still exhausting the worker pool. Tying timeouts to the caller's latency budget makes the number mean something.
4. **It pushes the fix to client construction.** A rule enforced per call site loses to the next forgetful edit; a rule enforced at the shared client wins by default.

## Origin

A checkout service called an internal tax-calculation service with a default no-timeout HTTP client. The tax service deployed a bad build that accepted connections but never responded; within four minutes the checkout service's entire worker pool was parked on those sockets and checkout went down sitewide. The tax bug was rolled back in ten minutes — the postmortem's only action item was a one-line timeout that should have been there from the first commit.
