---
title: No Hardcoded Dates in Test Fixtures
slug: no-hardcoded-dates-in-test-fixtures
category: testing
tags: [universal, testing, fixtures]
works_with: all
severity: high
one_liner: "Fixtures pinned to today's date that start failing next week"
---

# No Hardcoded Dates in Test Fixtures

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents time bombs: tests that pass today because the AI baked today's date into the fixture.

**[Copy-paste ready version](../../install/no-hardcoded-dates-in-test-fixtures.md)** — just the instruction block, no explanation.

## The Problem

The AI needs a "recent" order for a test, so it writes `created_at: "2026-06-10"` — today. The test checks that orders under 30 days old are refundable, and it passes beautifully for the next 29 days. On day 30 it fails for whoever happens to touch the repo, on a change that has nothing to do with refunds. The opposite version is just as common: `expiresAt: new Date('2027-01-01')` as "far future," which is fine until it isn't, usually during a holiday freeze when nobody remembers the fixture exists.

AI assistants do this because they generate fixtures by producing plausible literal data, and the most plausible date for "recent" is the current one from their context. They also write the live-clock variant — `Date.now() - 5 * DAY` inline in fixtures, mixed with hardcoded boundaries elsewhere in the same test — so the test's pass/fail depends on the relationship between a frozen literal and the wall clock at run time.

These failures are uniquely expensive per unit of bug, because they detonate on someone else's unrelated PR, weeks later, and the first hour of debugging is spent looking for what that PR broke. (It broke nothing. The calendar did.)

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No Hardcoded Dates in Test Fixtures

NEVER write a test whose outcome depends on the real current date or time. Any test mixing a hardcoded date literal with the live clock is a scheduled failure.

The core problem: a fixture date that means "recent" or "expired" *today* stops meaning that as the calendar moves, and the test fails later on an unrelated change.

Rules:
- Control the clock: freeze time with the framework's tool (`jest.useFakeTimers().setSystemTime(...)`, `freezegun.freeze_time(...)`, `time-machine`, injected clock) and write fixtures relative to the frozen moment
- If freezing isn't available, compute fixture dates from now (`now - 5 days`, `now + 1 year`) so their meaning is stable — never mix computed-from-now dates with literal dates in the same logic
- Hardcoded date literals are fine only when the test never consults the real clock: pure formatting/parsing tests, or fully frozen-time tests
- Watch the boundary cases you create: a fixture at exactly 30 days hits off-by-one differently depending on time of day. Place fixtures clearly inside or outside windows, and add explicit boundary tests with frozen time
- Treat "far future" literals (`2030-01-01`) as hardcoded dates too — they expire, just slower
- When you see an existing test fail on date math you didn't touch, say so: it's a time bomb to defuse, not a regression from the current change

**Red flags that you're about to violate this:**
- "I'll use today's date for the created_at field, it's realistic..."
- "2027 is far enough in the future, this'll never matter..."
- "The test passes now, the date logic must be fine..."
- "Freezing time is overkill for one little fixture..."
- "I'll just subtract a few days from new Date() right here inline..."

---

## Why It Works

1. **It names the actual hazard: mixing.** Literal dates aren't dangerous and clock reads aren't dangerous; their interaction is. Locating the rule there lets the AI keep writing natural fixtures in pure tests while catching the lethal combination.

2. **It makes "passes now" insufficient.** The AI's verification loop — run test, see green, done — cannot detect a time bomb by construction. Telling it that explicitly forces a different check: does this outcome depend on the wall clock?

3. **It removes the friction excuse.** The AI skips time-freezing because it feels like ceremony. Naming the exact one-line idioms per ecosystem turns it into the path of least resistance instead.

## Origin

A subscription-billing test suite went red across every open PR on the same morning. The culprit was a fixture an assistant had generated four months earlier: a trial account with a hardcoded signup date chosen to be "recently expired." That date had now drifted past a second threshold that triggered an entirely different account state. Three engineers independently debugged their own innocent PRs before anyone diffed the fixture file's git blame against a calendar.
