---
title: Raising the Timeout Is Not a Fix
slug: raising-the-timeout-is-not-a-fix
category: debugging
tags: [universal, debugging, root-cause]
works_with: all
severity: high
one_liner: "AI bumping timeout limits to mask hangs and slowness instead of fixing them"
---

# Raising the Timeout Is Not a Fix

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from responding to timeout errors by raising the limit until the complaint stops.

**[Copy-paste ready version](../../install/raising-the-timeout-is-not-a-fix.md)** — just the instruction block, no explanation.

## The Problem

`Error: timeout of 5000ms exceeded`. The AI's move: make it 15000ms. Still failing sometimes? 30000ms. The error stops, the ticket closes, and the question that the timeout existed to ask — *why is this operation suddenly taking more than five seconds?* — never gets answered. A timeout is a tripwire someone deliberately placed around an expected performance envelope. When it fires, either the envelope was always wrong (possible, occasionally) or something has started taking far longer than it should (usual). Raising the limit handles the first case and buries the second.

What's actually under a fired timeout, most of the time, is a real defect: an N+1 query that grew with the data, a missing index, a connection pool drained by a leak, a retry loop multiplying latency, a deadlock that resolves only when something else gives up, an external call that should be parallel running serially. Every one of these keeps getting worse, and the raised timeout doesn't just hide the symptom — it transfers the wait to users and to every system upstream, while guaranteeing the next firing happens at a worse stage of the rot.

Assistants reach for the limit because it's a one-line config change with immediate effect, and because "the operation needs more time" sounds like a diagnosis. It's a surrender phrased as one.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Raising the Timeout Is Not a Fix

NEVER respond to a timeout error by raising the timeout, except as a last step after establishing what the time is actually being spent on. A timeout is a performance tripwire someone set on purpose; when it fires, the question is "why is this slow?" — not "how do I stop being told it's slow?"

- First, measure: where do the seconds go? Profile, add timing logs around the suspect operation's phases, check query plans, inspect what the process is doing while "hung" (waiting on a lock? a serial chain of network calls? a full table scan?)
- Check the history: did this operation always run this long, or did it regress? If it regressed, that's a regression hunt (recent changes, data growth, dependency behavior), not a configuration question
- Fix the slowness where you find it: the missing index, the N+1, the serialized calls that should be concurrent, the leak draining the pool, the lock contention
- A raised timeout is legitimate only when the measurement shows the operation is *correctly* doing more work than the old envelope allows (data grew 10x, scope expanded) — state that evidence, and set the new value from the measured distribution, not by doubling until green
- Watch for the disguises: bumped retry counts, raised "grace periods," extended health-check windows, and lowered frequency of a slow job are all the same move with different names
- A timeout that fires intermittently is the early warning; the same bug fired it at 5s that will eventually hang it at any limit

**Red flags that you're about to violate this:**
- "The operation just needs more time to complete..."
- "Bumping the timeout to 30s resolves the failures..."
- "The default limit is too aggressive for this workload..." (measured against what?)
- "It only times out under load; a higher limit adds headroom..."
- Choosing the new limit by increasing it until the error stops
- Closing a timeout error without being able to say what the time is spent on

---

## Why It Works

1. **It restores the tripwire's meaning.** Reframing the timeout as a deliberately placed performance alarm makes raising it feel like disabling a smoke detector — which is the accurate frame — instead of tuning a parameter.

2. **It puts measurement before configuration.** "Where do the seconds go?" is answerable with cheap instrumentation, and once answered, the real defect (index, N+1, contention) is usually staring back; the instruction sequences that step before the config file can be touched.

3. **It allows the honest raise with a price.** Workloads do legitimately grow; requiring measured evidence and a distribution-derived value keeps that path open while killing "double it until green."

4. **It names the disguises.** Retry bumps and grace-period stretches are timeout raises wearing costumes; listing them prevents compliance-in-letter-only.

## Origin

A report endpoint began timing out for large accounts, and an assistant raised the limit from 10s to 60s — "the dataset has grown, the query needs more time." The dataset had grown by 4%. The actual change was a recently added filter running as a per-row subquery, turning a 2-second query into a 50-second one, getting slower every week. By the time it hit the 60s ceiling two months later, the table was bigger, the fix was riskier, and the largest customers had spent the interim watching a spinner for a minute per report.
