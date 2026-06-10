---
title: No Shared Mutable Test Fixtures
slug: no-shared-mutable-test-fixtures
category: testing
tags: [universal, testing, fixtures]
works_with: all
severity: medium
one_liner: "Module-level fixture objects mutated by one test and inherited by the next"
---

# No Shared Mutable Test Fixtures

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents tests from silently sharing one mutable fixture object that earlier tests have already bent out of shape.

**[Copy-paste ready version](../../install/no-shared-mutable-test-fixtures.md)** — just the instruction block, no explanation.

## The Problem

At the top of the test file sits `const baseOrder = { items: [...], status: 'pending' }`, and a dozen tests below it each grab `baseOrder` and go to work. Test four does `order.items.push(extraItem)` to set up its scenario. Test nine, written later, mysteriously sees four items where it expected three — but only when the whole file runs, not when it runs alone. Welcome to debugging by execution order.

AI assistants build this trap with the best intentions: extracting a shared fixture is textbook DRY, and module-level constants are where shared things go. What the pattern misses is that `const` protects the binding, not the contents — a pushed item, a reassigned field, a mutated nested object all persist across tests in the same process. Python's version is crueler: a mutable default in a fixture function, a class-level list, or a module-level dict mutated by `setUp` accumulates state in ways that depend on test selection. The resulting failures are maddeningly non-local — the test that breaks is innocent; the culprit ran earlier and passed.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No Shared Mutable Test Fixtures

NEVER let multiple tests share a mutable fixture object. Every test gets fresh data, built or cloned per test, so no test can inherit another test's mutations.

The core problem: `const`/module-level fixtures protect the reference, not the contents. One test pushes to an array or flips a field, and every later test in the process sees the altered object — producing failures that depend on execution order and vanish when tests run alone.

Rules:
- Use factory functions, not shared literals: `function makeOrder(overrides = {}) { return { items: [item()], status: 'pending', ...overrides }; }` — each call returns a new object graph
- Watch the shallow-copy trap: `{ ...baseOrder }` still shares the nested `items` array. Clone deep or (better) construct fresh
- In pytest, use function-scoped fixtures (the default) for anything mutable; treat `scope="module"`/`scope="session"` on mutable objects as a bug unless the fixture is genuinely read-only. Never use mutable default arguments in fixture helpers
- In JS, build mutable fixtures inside `beforeEach`, not at module load; module scope persists across every test in the file
- Shared *immutable* data (frozen constants, primitive config values) is fine — the rule is about anything a test can mutate
- Diagnostic: a test that fails in the full run but passes in isolation has, until proven otherwise, an order dependency — go looking for the shared object, not for a bug in the failing test

**Red flags that you're about to violate this:**
- "I'll hoist this fixture to module level so all the tests can reuse it..."
- "DRY applies to test data too, one baseUser for everyone..."
- "A spread copy is enough, the tests barely modify it..."
- "Session-scoped fixtures are faster, and these tests only read the data..."
- "I'll just push the extra item onto the shared list for this one case..."

---

## Why It Works

1. **It names the const illusion.** The AI genuinely believes `const`/top-level extraction makes data safe to share. Stating that the binding is protected but the contents aren't corrects the specific misunderstanding driving the pattern.

2. **It redirects DRY rather than fighting it.** The AI extracts fixtures because deduplication is trained-in good practice. Factory functions satisfy the same instinct — one definition, many uses — while making freshness structural instead of disciplined.

3. **It hands over the diagnostic.** "Fails in suite, passes alone" is the signature of this bug, and the AI's default move is to debug the *failing* test. Pointing the search at shared state saves the hour that mis-aimed debugging costs.

## Origin

A test file for a cart module had a module-level `sampleCart` reused by nineteen tests. A new test failed in CI but passed locally every time the engineer ran it — locally she ran it by name. The cause was a test added months earlier (by an assistant, for a bulk-discount case) that pushed six items into the shared cart and passed happily. Three engineers, several "cannot reproduce" comments, and most of a day went into discovering that the failing test had never been broken at all.
