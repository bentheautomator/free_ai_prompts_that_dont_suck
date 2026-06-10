---
title: No Timeout Bumps to Pass Tests
slug: no-timeout-bumps-to-pass-tests
category: testing
tags: [universal, testing, flaky]
works_with: all
severity: high
one_liner: "AI raising test timeouts to mask hangs and performance regressions"
---

# No Timeout Bumps to Pass Tests

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from treating every timeout failure as a too-small number instead of a too-slow program.

**[Copy-paste ready version](../../install/no-timeout-bumps-to-pass-tests.md)** — just the instruction block, no explanation.

## The Problem

A test that ran in 800ms for two years suddenly exceeds its 5-second timeout, and the AI's response is `jest.setTimeout(30000)` — or `@pytest.mark.timeout(60)`, or `--testTimeout=30000` in the config, escalating the whole suite at once. The test passes at 22 seconds. The AI reports it fixed. What actually happened is that something made the code 25x slower — an accidental N+1 query, a retry loop hammering a dead endpoint, a connection pool drained by the AI's own change — and the only alarm wired to that fact was just turned up past the noise.

Timeouts in tests aren't arbitrary patience settings; they're crude performance assertions. A timeout failure says "this used to be fast and now it isn't," which is among the most valuable signals a suite produces, because performance regressions are otherwise invisible until production. The AI bumps the number because the failure message literally says "exceeded timeout," and increasing the stated limit is the most direct textual response to it — the error names the threshold, not the slowness, so the AI fixes the threshold.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No Timeout Bumps to Pass Tests

NEVER respond to a test timeout by raising the timeout, until you have measured what the test actually does with the time and explained why the duration is legitimate. A timeout is a performance assertion; bumping it is weakening an assertion.

The core problem: a test that newly exceeds its timeout is usually reporting that the code got slower — a hang, a retry storm, an N+1 query. Raising the limit silences the report and ships the slowness.

When a test times out:
- First ask: did this test pass within the limit before? If yes, something regressed — find it. Diff the recent changes, profile the test, log timestamps around the slow section
- Distinguish hang from slow: a test that times out at any limit (deadlock, unawaited promise, missing event) will not be fixed by 30 seconds; it will fail in 30 seconds instead of 5
- Check whether your own change introduced the slowness before blaming infrastructure
- Never raise the global/default timeout to fix one test. That weakens the performance assertion on every test in the suite
- A targeted increase is legitimate when the test genuinely does more than before (you added cases, the fixture grew) — state the new expected duration and why, and scope the increase to that one test
- If the operation is legitimately slow because it does real I/O a unit test shouldn't do, the fix is the test's design, not its budget

**Red flags that you're about to violate this:**
- "CI machines are just slow, I'll give it more headroom..."
- "Doubling the timeout is the quick fix, I'll investigate later..."
- "The error says timeout exceeded, so the timeout is the problem..."
- "I'll bump the global timeout so this stops happening anywhere..."
- "It passes at 30 seconds, so it works..."

---

## Why It Works

1. **It reframes the timeout as an assertion.** The AI categorizes timeouts as infrastructure config, fair game for tuning. Recasting them as performance assertions moves bumps into the "weakening assertions" category, where the AI already has guardrails.

2. **It breaks the error message's framing.** "Exceeded timeout of 5000ms" syntactically blames the number, and the AI follows the syntax. Explicitly separating "the limit" from "the duration" redirects attention to the thing that changed.

3. **It distinguishes hang from slow.** Half of timeout bumps are applied to deadlocks, where they fix nothing and waste 30 seconds per run forever. Forcing that diagnosis first prevents the entirely futile subset outright.

4. **It protects the global setting.** Suite-wide bumps are the worst variant — one slow test degrading the performance alarm on hundreds. Singling that move out closes the laziest path.

## Origin

After a dependency upgrade, three API tests began timing out. The assistant raised the suite default from 5 to 60 seconds and reported all green. The upgrade had changed the HTTP client's retry policy to five retries with exponential backoff against an endpoint that was returning 503 in the test environment — the same misconfiguration existed in production staging, where p99 latency had quietly gone from 200ms to 40 seconds. The timeouts were the only signal, and they'd been paid off.
