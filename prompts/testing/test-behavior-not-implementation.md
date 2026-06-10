---
title: Test Behavior, Not Implementation
slug: test-behavior-not-implementation
category: testing
tags: [universal, testing]
works_with: all
severity: medium
one_liner: "Tests welded to private internals that break on every harmless refactor"
---

# Test Behavior, Not Implementation

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents tests that assert how the code works inside instead of what it does outside.

**[Copy-paste ready version](../../install/test-behavior-not-implementation.md)** — just the instruction block, no explanation.

## The Problem

The test doesn't check that the cache returns the right value — it checks that `_evictLRU` was called exactly twice, that the internal `_store` Map has size 3, and that `helper.normalize` ran before `helper.validate`. Every one of those facts is true of the current implementation and none of them is the contract. Next month someone swaps the Map for an LRU library, behavior identical, and nine tests go red. The lesson the team learns is the worst one available: red tests mean nothing, just update them until they're green again.

AI assistants write implementation-welded tests because they generate tests by *reading the code* — and what the code makes visible is its mechanism. Private methods, call sequences, and internal structures are right there to assert on, while the actual contract (what callers can rely on) exists in heads and docs the AI may not consult. Spy frameworks make it worse by making mechanism assertions one-liners: `expect(spy).toHaveBeenCalledTimes(2)` is easier to produce than working out what observable result those two calls should have caused. The suite ends up failing on refactors (false alarms) while missing behavioral bugs that keep the internal choreography intact — wrong in both directions.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Test Behavior, Not Implementation

Test what the code promises to callers — inputs, outputs, observable effects — NEVER its private mechanism. A good test survives any refactor that preserves behavior and fails on any change that breaks it.

The core problem: assertions on private methods, internal call counts, and hidden data structures pin the *current implementation* in place. They fail on harmless refactors, training people to ignore red, while passing on real bugs that keep the internal choreography intact.

Rules:
- Assert through the public surface: return values, raised errors, emitted events, persisted records, rendered output. If a fact isn't observable to a caller, think hard before asserting it
- Don't test private methods directly (reaching into `_method`, rebinding privates, `@VisibleForTesting` escalation). If a private is complex enough to demand its own tests, that's a hint it wants to be a separately tested unit
- Don't assert internal call order or call counts of the unit's own helpers (`expect(this._normalize).toHaveBeenCalledBefore(...)`) — assert the result that correct ordering produces
- Call counts ARE the behavior at external boundaries: "charges the card exactly once" or "sends one email" are contracts; assert those freely. The line is whether the collaborator is part of the unit or part of the world
- In UI tests, query by role/text/label the user perceives, not by internal class names or component instance state
- Litmus test before finishing: would this test still pass if the implementation were rewritten from scratch with identical behavior? If no, you've tested the mechanism

**Red flags that you're about to violate this:**
- "I'll spy on the internal helper to make sure it's invoked..."
- "Asserting the private state directly is more precise..."
- "Checking the call sequence proves the algorithm is right..."
- "I'll export this private function just so the test can reach it..."
- "Testing through the public API is too indirect..."

---

## Why It Works

1. **It gives the refactor litmus test.** "Would this survive a behavior-preserving rewrite?" is a single concrete question that separates contract from mechanism, replacing the vague "don't over-couple" advice the AI can't operationalize.

2. **It resolves the call-count ambiguity.** A blanket ban on call assertions would be wrong — "charged once" is a real contract. Drawing the line at unit-internal vs. external boundary removes the ambiguity the AI exploits in both directions.

3. **It explains the double cost.** The AI assumes tighter assertions are safer. Spelling out that mechanism tests fail wrong (refactors) *and* pass wrong (behavioral bugs with intact choreography) corrects the safety intuition driving the pattern.

## Origin

A pricing engine refactor — pure restructuring, outputs verified identical — turned 60 of 200 tests red, all asserting on private call sequences and internal accumulator state an assistant had spied into over months of test generation. Updating them took two days, during which a real regression (a discount cap applied in the wrong order, changing actual totals) was waved through in the same batch as "more refactor fallout." The suite had inverted its purpose: loud about restructuring, silent about behavior.
