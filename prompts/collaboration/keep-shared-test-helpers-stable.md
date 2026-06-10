---
title: Keep Shared Test Helpers Stable
slug: keep-shared-test-helpers-stable
category: collaboration
tags: [universal, teamwork, testing]
works_with: all
severity: high
one_liner: "Stops deleting or renaming test helpers that other suites depend on"
---

# Keep Shared Test Helpers Stable

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from deleting, renaming, or repurposing shared test utilities that other test suites quietly depend on.

**[Copy-paste ready version](../../install/keep-shared-test-helpers-stable.md)** — just the instruction block, no explanation.

## The Problem

Test helpers — `createTestUser()`, `setupTestDb()`, `mockAuthMiddleware()`, the factory functions in `tests/support/` — are the most shared code in many repos and the least respected. The AI, refactoring a test file or cleaning up after itself, decides a helper is "unused" because its own suite no longer calls it, renames `buildOrder` to `makeOrder` for consistency, or changes a factory's defaults so its new test passes. Then forty tests across six suites fail, or worse, keep passing while testing something different than before.

The "worse" case deserves emphasis. A factory that used to create an active user and now creates a pending one doesn't break tests — it quietly changes what every downstream test verifies. Suites that existed to pin down active-user behavior are now exercising pending-user behavior, and the regression they were guarding against can walk right through. Nobody finds this in CI. They find it in production, months later, with a green test history the whole way down.

The AI does this because test code reads as low-stakes — it's "just tests" — and because helper usage is spread across files it never opened. A helper with thirty call sites looks identical, from inside one test file, to a helper with one.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Keep Shared Test Helpers Stable

NEVER delete, rename, or change the behavior of a shared test helper, fixture factory, or test setup function without first finding every test that uses it. Test helpers have more callers than most production code and weaker protection.

Changed defaults are the dangerous case: tests keep passing while silently verifying something else.

- Before touching anything in `tests/support/`, `test/helpers/`, `testutils/`, `conftest.py`, shared `setup`/`teardown` modules, or any factory file, search the entire repo for usages — across all suites, not just the one you're in.
- "Unused in this file" is not "unused." Helpers exist precisely to be called from many places.
- Never change a factory's defaults to suit your new test. Pass overrides at your call site, or add a new named factory variant. Other tests encoded their assumptions in those defaults.
- Renaming for consistency is not worth it unless you update every call site in the same change and say so.
- If a helper genuinely is dead (zero call sites after a real search), deleting it is fine — state the search you did.
- Treat behavior broadly: return shapes, created-record state, seeded IDs, cleanup behavior, randomness/seeding. Tests depend on all of it.

**Red flags that you're about to violate this:**
- "My suite doesn't use this helper anymore, so it's dead code."
- "I'll change the factory default; one field, who'll notice."
- "Renaming this helper makes the test code more consistent."
- "It's test code — breaking it is low risk."
- "The other suites probably use their own helpers."

---

## Why It Works

1. **It corrects a severity misranking** — the AI treats test code as low-stakes, but shared helpers are high-fan-in infrastructure, and the rule re-weights them accordingly.
2. **It targets the silent failure mode by name**: changed defaults that keep tests green while changing what they verify, which no CI signal will ever catch.
3. **It replaces "looks unused" with "searched and found zero callers"** — converting a guess based on one file into a checkable claim about the repo.
4. **It offers override-at-call-site as the default move**, which satisfies the new test's needs with exactly zero blast radius.

## Origin

An assistant changed `createTestAccount()` in a shared conftest to default `verified=True`, because its new tests needed verified accounts and passing the flag everywhere felt repetitive. One hundred and twelve existing tests used that factory; dozens of them existed specifically to verify how unverified accounts were handled. All stayed green — now testing verified accounts twice. A month later a change broke the unverified-account flow in production, untouched by a test suite that had been rendered decorative in a single line.
