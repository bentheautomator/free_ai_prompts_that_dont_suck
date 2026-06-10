---
title: Test Names Must Match What They Assert
slug: test-names-must-match-what-they-assert
category: testing
tags: [universal, testing]
works_with: all
severity: medium
one_liner: "Tests named for behaviors their bodies never actually check"
---

# Test Names Must Match What They Assert

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents tests whose names promise verification their assertions don't deliver.

**[Copy-paste ready version](../../install/test-names-must-match-what-they-assert.md)** — just the instruction block, no explanation.

## The Problem

The test is named `it('retries failed requests with exponential backoff')`. The body calls the function once, with a mock that succeeds immediately, and asserts the response came back. No failure is induced, no retry occurs, no timing is measured — the name describes a behavior the body never goes near. Variants are everywhere in AI-generated suites: `test_handles_invalid_input` that only passes valid input, `'gracefully degrades when cache is down'` with the cache mock fully operational, `test_concurrent_updates_are_serialized` that performs one update.

The mismatch happens because AI assistants write the name from the *requirements* (what should be tested) and the body from the *achievable* (what was easy to set up) — and when inducing the failure or the concurrency proved fiddly, the body quietly settled for a happy-path call while the name kept its ambitions. Names are the suite's user interface: people grep them to answer "is X tested?", reviewers skim them in PR output, coverage discussions cite them. A name that overpromises doesn't just fail to test X — it actively blocks anyone from noticing X is untested, because every search for it comes back reassuringly green.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Test Names Must Match What They Assert

A test's name is a claim, and the body must back it. NEVER name a test for a behavior its assertions don't actually verify — an overpromising name is how a gap in coverage hides from everyone who looks for it.

The core problem: people audit suites by reading names, not bodies. `test_handles_invalid_input` that never passes invalid input doesn't just skip the check — it answers "is invalid input tested?" with a false yes, forever.

Rules:
- After writing a test, reread the name as a checklist against the body: every behavior-word in the name (retries, rejects, concurrent, gracefully, rolls back, validates) must correspond to something the test sets up and asserts. "Retries" requires an induced failure and an assertion about subsequent attempts; "rejects" requires the bad input and the rejection
- If you couldn't make the named scenario happen — the failure was hard to induce, the concurrency was fiddly — rename the test to what it actually does, and report the named scenario as still untested. Do not let the name keep the ambition the body abandoned
- Name what's asserted, not the setup vibe: `'returns cached value when present'` beats `'cache works correctly'` — and if a name resists being specific, the test probably asserts too little or too much
- One claim per name where practical; a name with "and" in it usually contains an unverified half
- Words that earn extra suspicion in your own output: "gracefully," "correctly," "properly," "handles," "robust" — they describe a feeling, and bodies rarely assert feelings
- When auditing existing suites, treat name/body mismatches as findings worth surfacing: each one is a question someone will answer wrongly by grepping

**Red flags that you're about to violate this:**
- "The name reflects what this test is meant to cover eventually..."
- "Setting up the actual failure is complex, but the test still has the right title..."
- "handles invalid input sounds better than rejects empty string..."
- "The name comes from the ticket, the body does what was feasible..."
- "Close enough — the test is in the right area..."

---

## Why It Works

1. **It identifies the name as an interface.** The AI treats names as labels; humans use them as an index of what's verified. Establishing that names are *read instead of bodies* explains why an overpromise is an active hazard rather than a cosmetic slip.

2. **It installs a name-as-checklist pass.** Re-reading each behavior-word against the body is a mechanical audit the AI can run on its own output, catching the drift between ambitious naming and convenient implementation at the moment it happens.

3. **It makes the honest downgrade available.** The mismatch persists because renaming feels like admitting failure. Explicitly pairing "rename to what it does" with "report the gap" turns the retreat into a deliverable instead of a concession.

## Origin

Before a traffic surge event, a team grepped their suite for resilience coverage and found `'falls back to stale cache when upstream times out'` passing in CI — and moved on. The body mocked the upstream as healthy and asserted a normal response; the fallback path it named had never been executed by any test. Under the surge, the real fallback deadlocked on a lock the happy path never took. The retro's finding was that the coverage audit had been correct *about the names* — which was the problem.
