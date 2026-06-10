---
title: Don't Mock Everything in Integration Tests
slug: dont-mock-everything-in-integration-tests
category: testing
tags: [universal, testing, mocking]
works_with: all
severity: high
one_liner: "Integration tests so mocked they only verify mocks talking to mocks"
---

# Don't Mock Everything in Integration Tests

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from mocking away every collaborator until the "integration" test integrates nothing.

**[Copy-paste ready version](../../install/dont-mock-everything-in-integration-tests.md)** — just the instruction block, no explanation.

## The Problem

The file is called `checkout.integration.test.ts`. Inside: the payment client is mocked, the inventory service is mocked, the order repository is mocked, the event bus is mocked, and the notification sender is mocked. What remains under test is a thin controller method that calls five mocks in sequence — and the test verifies it calls five mocks in sequence. Every seam where components could actually disagree (the repository expects a different field name; the event payload shape changed; the inventory call happens after payment when it must happen before) has been replaced with a stub that agrees with whatever it's handed.

AI assistants escalate to this because each individual mock solves a real, immediate problem: the test errored on a missing connection, a credential, an unstarted service. Mocking the erroring dependency is the local fix, and applied five times in a row it quietly converts an integration test into a unit test of glue code — while keeping the filename and the misplaced confidence. The defects integration tests exist to catch live precisely in the interactions that were stubbed out.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Don't Mock Everything in Integration Tests

NEVER mock away so many collaborators that a test no longer exercises any real interaction between real components. Before adding each mock, name what the test still verifies if the mock goes in — and stop when the answer approaches "that the mocks get called."

The core problem: every mock replaces a seam where real components could disagree with a stub that always agrees. Mock all the seams and the test can no longer fail for any reason that matters.

Rules:
- Decide the test's integration boundary explicitly and state it: which real components talk to each other, and where the world is faked. "Service + real repository + in-memory DB, with the external payment API faked" is a boundary; "mock whatever errors" is not
- Mock at the system's edges (third-party APIs, payment processors, email), not between your own components — inter-component contracts are the thing integration tests exist to check
- Prefer real-ish substitutes over interaction stubs: in-memory or containerized databases, the framework's test client/server, fakes with actual behavior (a real in-memory queue) rather than `mock.calledWith` choreography
- When a dependency errors in test setup, the first option is to provide it (test container, fixture, in-process fake), not to stub it. Stubbing-on-error is how integration tests dissolve one mock at a time
- If the environment truly can't support the real dependency, say so and ask, rather than silently downgrading the test's meaning while keeping its name
- Honesty rule: a test where every collaborator is mocked is a unit test. Name it as one or rebuild it

**Red flags that you're about to violate this:**
- "The DB isn't available here, I'll mock the repository too..."
- "Mocking all the services makes this test fast and reliable..."
- "It still tests the flow — each step is verified to be called..."
- "One more mock won't change what the test covers..."
- "I'll mock it now so the test runs, and it can be made real later..."

---

## Why It Works

1. **It interrupts the one-mock-at-a-time ratchet.** No single mock looks fatal; the test dies of accumulation. Requiring "what does this still verify?" before *each* mock makes the cumulative erosion visible at the moment it can be stopped.

2. **It draws the line at ownership.** "Mock the edges, not between your own components" gives a checkable rule for where stubs belong, replacing vibes about "too much mocking" with a boundary the AI can apply mechanically.

3. **It reframes setup errors.** The trigger for over-mocking is an erroring dependency, which the AI reads as "this needs a mock." Recasting it as "this needs to be provided" points at containers, fakes, and fixtures — solutions that preserve the test's meaning.

## Origin

A checkout integration suite — twelve tests, all green for a year — failed to catch a deploy where the order service and inventory service disagreed on a renamed field, because every test mocked the inventory client with the old shape. The mismatch caused silent inventory drift in production for nine days. The postmortem's memorable line: the integration tests had verified, with great rigor, that mocks our team wrote were consistent with other mocks our team wrote.
