---
title: No Test Order Dependencies
slug: no-test-order-dependencies
category: testing
tags: [universal, testing, isolation]
works_with: all
severity: high
one_liner: "Tests that only pass because an earlier test ran first and left state behind"
---

# No Test Order Dependencies

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from writing tests that depend on artifacts created by earlier tests in the run.

**[Copy-paste ready version](../../install/no-test-order-dependencies.md)** — just the instruction block, no explanation.

## The Problem

Test one creates a user. Test two logs that user in. Test three updates the profile that test two's login made accessible. It reads like a tidy story, and the AI writes it that way deliberately — reusing test one's user in test two "avoids duplicate setup." The suite passes top to bottom. Then someone runs test three alone and it explodes; or the runner parallelizes (`pytest-xdist`, Jest's default worker pool) and tests land in different processes; or someone enables random ordering and the suite fails differently every run. Each test was only ever valid as a continuation of the previous one.

AI assistants create these chains because they read the test file as a narrative and optimize away "redundant" setup that is actually each test's independence. They also create them accidentally: a test that registers `user@example.com` passes alone, then a second test registering the same email fails with a uniqueness violation — coupling by leftover, not by design. Either way, the suite's results become a function of which tests ran, in what order, in which process — which is to say, not a function of the code.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No Test Order Dependencies

Every test must pass when run alone, and pass when run in any order. NEVER write a test that consumes state — records, files, logins, caches, globals — created by another test.

The core problem: order-dependent tests aren't individually meaningful; they're steps in a script. The moment the runner parallelizes, randomizes, filters, or someone runs one test by name, the script breaks and the failures point at innocent tests.

Rules:
- Each test creates what it needs. If three tests need a registered user, each builds one (via factory or fixture) — shared *setup code* is good; shared *runtime state* is the bug
- Never reference by name or ID something a previous test created ("the user from the signup test"). If you're tempted, that setup belongs in a fixture both tests call
- Clean up or randomize side effects: unique emails/usernames per test (`f"user-{uuid4()}@test"`), per-test temp dirs, transaction rollback or truncation between tests — so leftovers can't couple tests by accident
- Do not "fix" an order-dependent failure by reordering tests, renaming files to control run order, or disabling parallelism/randomization in the runner config. Those lock the dependency in; fix the dependency
- Multi-step flows that genuinely must be sequential (signup then login then purchase) belong inside ONE test as explicit steps, not spread across three tests holding hands
- Verification that means something: run the new test by itself, and run the file with order randomized if the runner supports it (`pytest -p randomly`, `--random-order`)

**Red flags that you're about to violate this:**
- "Test two can reuse the account test one just created..."
- "Recreating the user in every test is wasteful duplication..."
- "I'll move this test above the other one so the data exists by then..."
- "It passes when the whole file runs, that's what CI does anyway..."
- "I'll disable parallel execution for this file, the tests need their order..."

---

## Why It Works

1. **It distinguishes shared code from shared state.** The AI deduplicates setup because DRY is trained-in; the rule preserves that (fixtures, factories) while banning the harmful version (runtime leftovers), so the instinct has a correct outlet.

2. **It bans the band-aids by name.** Reordering tests, alphabetical filename tricks, and turning off parallelism all "work" and all entrench the bug. Enumerating them keeps the AI from resolving the symptom while compounding the cause.

3. **It provides the sequential escape hatch.** Some flows are honestly ordered. "Put the steps in one test" gives that need a legitimate home, removing the justification for cross-test chains.

## Origin

A suite of API tests ran clean for months until the team enabled parallel workers to cut CI time. Forty-one tests failed in patterns that changed every run. The chains traced back to an assistant's "test cleanup" commit that had deduplicated setup by making later tests reuse earlier tests' records — praised in review for cutting 200 lines. Untangling it took longer than the parallelization saved that quarter.
