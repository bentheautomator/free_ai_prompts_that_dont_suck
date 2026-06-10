---
title: Investigate Flaky Tests Before Removal
slug: investigate-flaky-tests-before-removal
category: testing
tags: [universal, testing, flaky]
works_with: all
severity: critical
one_liner: "AI axing a flaky test that was the only thing catching a real race"
---

# Investigate Flaky Tests Before Removal

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from declaring a test "flaky" and removing it when the flake is a real intermittent bug.

**[Copy-paste ready version](../../install/investigate-flaky-tests-before-removal.md)** — just the instruction block, no explanation.

## The Problem

"Flaky" is the most dangerous word in testing, because it's a diagnosis that requires no evidence and licenses any treatment. A test that fails one run in five gets labeled flaky, and once labeled, the AI feels authorized to remove it — the test is the problem, removal is the cure, and "deleted flaky test" reads like housekeeping in a commit log. But a test that intermittently fails is making a precise factual claim: *this code intermittently does the wrong thing under these conditions.* Sometimes the nondeterminism lives in the test (shared state, timing assumptions). Sometimes it lives in the code — a race condition, a missing lock, an unordered query — and the "flaky" test is the only instrument in the building that can detect it.

AI assistants can't tell these apart without investigating, and they don't investigate, because the flaky label arrives pre-installed: the user said "fix the flaky tests," or a previous run failed and a retry passed. Retry-passes feel like exoneration. They aren't — a race condition also passes on retry. That's what makes it a race.

Delete the test and you haven't fixed the nondeterminism; you've fired the witness.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Investigate Flaky Tests Before Removal

NEVER remove, disable, or quarantine a test because it fails intermittently, until you have determined *why* it fails intermittently. "Flaky" is a symptom, not a diagnosis — and one of its common causes is a real race condition in the code under test.

The core problem: an intermittent failure means something is nondeterministic. If that something is the production code, the test is your only detector, and removing it ships the race.

Before touching an intermittent test:
- Reproduce it: run the test in a loop (`pytest --count`, `jest --testNamePattern` in a shell loop, `go test -count=100 -race`) and record the failure rate and the exact failure output
- Read the failure. A timeout, a wrong value, and a missing record point to different causes. Distinguish "the test assumed ordering the code never promised" from "the code corrupts state under concurrency"
- Locate the nondeterminism: test-side (shared fixtures, sleeps, port collisions, leftover state) or code-side (races, unawaited async, unordered iteration). Use the race detector or thread sanitizer where the ecosystem has one
- If it's test-side, fix the test's determinism and prove it with a loop run
- If it's code-side, you found a real bug — report it as one. The test stays
- If you cannot determine the cause, say so and leave the test in place. An honest intermittent red beats a confident permanent blind spot

**Red flags that you're about to violate this:**
- "It passed on retry, so it's just flaky..."
- "This test has been unreliable forever, removing it unblocks everyone..."
- "Intermittent failures are test infrastructure problems by definition..."
- "I can't reproduce it locally, so it can't be a real bug..."
- "The team already calls it flaky, I'm just acting on that..."

---

## Why It Works

1. **It severs label from license.** The word "flaky" smuggles in a conclusion (the test is at fault) that authorizes removal. Reclassifying it as a symptom forces the diagnostic step the label was built to skip.

2. **It debunks retry-as-exoneration.** "Passed on retry" is the single thought that most often precedes deletion, and it's evidentially worthless against races. Saying so directly removes the AI's main justification.

3. **It demands evidence with teeth.** Loop runs, failure-rate numbers, and reading the actual error are concrete acts that either find the cause or honestly fail to — both outcomes block the lazy delete.

4. **It makes the inconclusive case safe.** Without an explicit "leave it red and say so" option, the AI resolves uncertainty by removal because removal at least terminates the task.

## Origin

A checkout suite had one test that failed roughly weekly, always on the inventory-decrement step. An assistant tasked with "cleaning up flaky tests" removed it, noting it "failed nondeterministically and blocked CI." The nondeterminism was a race between two order paths decrementing stock without a lock — which, eight weeks later, oversold a limited product drop by several hundred units. The deleted test had been reproducing the race on roughly one run in forty, which was more often than anyone reproduced it afterward.
