---
title: Don't Monopolize Shared Test Resources
slug: dont-monopolize-shared-test-resources
category: collaboration
tags: [universal, teamwork, testing]
works_with: all
severity: medium
one_liner: "Stops claiming shared test envs, fixtures, and ports as if they were yours"
---

# Don't Monopolize Shared Test Resources

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from treating shared test environments, fixtures, databases, and ports as exclusively its own.

**[Copy-paste ready version](../../install/dont-monopolize-shared-test-resources.md)** — just the instruction block, no explanation.

## The Problem

Some resources are one-per-team, not one-per-developer: the staging environment, the shared test database, the seeded fixture records everyone's integration tests read, well-known local ports, the single set of test API credentials with a rate limit. The AI treats whatever it can reach as available: it points destructive tests at the shared staging database, mutates the canonical seeded records (`user id 1`, the `acme-test` org) that fifty other tests assume pristine, hardcodes port 5432 or 8080 for its test server, deploys its experiment to the shared environment over whatever was being tested there, and burns the team's API quota running a retry loop.

The cost lands on whoever shares the resource. Another developer's test run fails because the fixture data changed underneath it. The QA engineer's afternoon of staging verification is invalidated by a surprise deploy. Two developers' test suites can't run simultaneously because both bind the same hardcoded port. None of these failures point back at the cause — they look like flakiness, which is the most expensive kind of failure to chase, and they slowly teach the team that shared resources can't be trusted.

The AI behaves this way because resources have no visible occupancy. A database it can connect to looks free. A port that binds looks free. It optimizes for its task with the resources at hand, and "at hand" and "mine to consume" are different things only humans know about.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Don't Monopolize Shared Test Resources

NEVER treat a shared resource as exclusively yours. Test environments, seeded fixtures, shared databases, well-known ports, and shared credentials are concurrent-use infrastructure — assume someone else is using them right now, because someone usually is.

Reachable is not the same as available. Damage to shared resources surfaces as other people's "flaky" failures, which never trace back to you.

- Prefer isolated resources: spin up a local/ephemeral database or container, create your own test records, use a temp directory, bind to port 0 or a randomly assigned port rather than hardcoding a well-known one.
- Never mutate or delete canonical seeded data (the well-known test users, orgs, and records) that other tests read. Create your own entities, namespaced or randomized so they can't collide, and clean them up.
- Never run destructive or schema-altering operations against a shared environment without the human explicitly confirming it's safe and free.
- Don't deploy experiments to shared environments on your own initiative — someone may be mid-verification there. Ask first.
- Respect shared quotas: no unbounded retry loops or load tests against shared credentials or rate-limited test accounts.
- If the task seems to require exclusive use of a shared resource, say so and let the human coordinate the reservation. That's a calendar problem, not a code problem.

**Red flags that you're about to violate this:**
- "The staging DB is right there in the config; I'll test against it."
- "I'll just modify test user 1; it's test data."
- "Port 8080 is the standard port, so I'll hardcode it."
- "Truncating these tables gives me a clean slate."
- "Nobody seems to be using staging right now."

---

## Why It Works

1. **It replaces "reachable" with "occupied until proven otherwise,"** correcting the AI's only available heuristic, which is connectivity.
2. **It makes isolation the default move** — own records, ephemeral databases, random ports — which removes the contention rather than managing it.
3. **It names the flakiness laundering effect**: shared-resource damage shows up as unattributable failures in other people's runs, so the feedback loop that would normally correct the behavior never fires.
4. **It separates code problems from coordination problems**, routing exclusive-use needs to humans who can actually see who else is mid-test.

## Origin

An assistant's integration tests needed a clean database, so they truncated all tables in the shared test DB during setup — fast, effective, and run on every test invocation. For two weeks the rest of the team experienced randomly failing integration tests as their seeded data vanished mid-run, depending on timing. It was diagnosed as flakiness, three "fix flaky test" tickets were filed, and one developer rewrote a perfectly good test suite before someone noticed the truncation in another suite's setup code.
