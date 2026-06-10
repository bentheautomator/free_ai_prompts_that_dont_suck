---
title: Break Identical Retry Loops After Two Failures
slug: break-identical-retry-loops
category: agents-and-automation
tags: [universal, agents, loops]
works_with: all
severity: critical
one_liner: "Agents rerunning the exact same failing command ten times in a row"
---

# Break Identical Retry Loops After Two Failures

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the agent from rerunning a command that just failed, unchanged, over and over, until the session budget is gone.

**[Copy-paste ready version](../../install/break-identical-retry-loops.md)** — just the instruction block, no explanation.

## The Problem

A command fails. The agent runs it again. Same command, same environment, same error. Then again. Anyone who has watched a long autonomous session has seen the transcript where `npm test` fails with the identical stack trace fifteen consecutive times, each attempt prefixed with a cheerful "Let me try running the tests again." Nothing changed between attempts, so nothing could have changed in the result — but the agent keeps pulling the lever.

This happens because each retry is locally reasonable. From inside a single step, "try again" feels like diligence, and the agent never steps back to count how many times it has already tried. Deterministic failures don't announce themselves as deterministic; the error message looks the same on attempt twelve as it did on attempt one, and the agent treats each one as fresh news.

The cost is real. Retry loops burn API spend, eat the context window with duplicate error output, and can hammer external services — fifteen failed deploy attempts is fifteen entries in someone's incident channel. By the time a human intervenes, the session has often spent its entire budget producing one error message in bulk.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Break Identical Retry Loops After Two Failures

NEVER run the same command a third time after it has failed twice with the same error. Two identical failures prove the failure is deterministic; a third attempt is a loop, not persistence.

The core problem: each retry feels reasonable in isolation, so you never notice you're looping. You must count attempts explicitly.

- Before rerunning anything that just failed, state what changed since the last attempt. If the answer is "nothing," do not run it.
- "Maybe it was transient" covers exactly one retry. Network calls, flaky tests, and race conditions get one repeat attempt — not five.
- After the second identical failure, stop executing and diagnose: read the full error, read the relevant code or config, and form a hypothesis about the cause before touching the command again.
- If diagnosis doesn't produce a concrete change to make, report the failure to the user with the exact error and what you ruled out. A short honest report beats a long transcript of identical failures.
- Track your own attempt count per command within the session. If you notice the same error text appearing for the third time anywhere in your recent history, treat it as a hard stop.
- Never retry against external services (deploys, API calls, package publishes) without backoff and an explicit reason to expect a different result.

**Red flags that you're about to violate this:**
- "Let me just try running it one more time..."
- "It might have been a transient issue..." (for the fourth time)
- "Sometimes these things resolve themselves..."
- "I'll run it again to confirm the error..." (you already have the error, twice)
- "Maybe the cache cleared by now..."

---

## Why It Works

1. **It installs a circuit breaker with a number on it.** "Don't loop" is unenforceable because the agent never thinks it's looping. "Never a third identical attempt" is checkable at the moment of decision.

2. **It reframes retrying as a claim, not an action.** Requiring "state what changed since the last attempt" converts a reflex into an assertion the agent has to back up — and "nothing changed" is self-evidently disqualifying.

3. **It caps the transient-failure excuse.** The rationalization that powers most retry loops is "maybe it was flaky." Granting exactly one retry for that theory acknowledges the legitimate case while closing the infinite one.

4. **It defines the exit ramp.** Agents loop partly because stopping feels like failure. Making "report the error and what you ruled out" an explicitly sanctioned outcome gives the loop somewhere to terminate besides budget exhaustion.

## Origin

An overnight agent session was asked to get a test suite green before morning. One test failed on a missing environment variable; the agent ran the full eleven-minute suite forty-one more times without changing anything, reasoning each time that the failure "might be intermittent." The session burned its entire token budget and roughly seven hours of wall-clock time producing the same error, and the actual fix — one line in an env file — was made by a human before coffee.
