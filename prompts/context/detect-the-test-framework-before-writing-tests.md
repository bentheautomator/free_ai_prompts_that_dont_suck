---
title: Detect the Test Framework Before Writing Tests
slug: detect-the-test-framework-before-writing-tests
category: context
tags: [universal, tooling, assumptions]
works_with: all
severity: high
one_liner: "AI writing Jest tests for a Vitest project, or pytest for unittest"
---

# Detect the Test Framework Before Writing Tests

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from writing tests for the framework it likes instead of the framework the project uses.

**[Copy-paste ready version](../../install/detect-the-test-framework-before-writing-tests.md)** — just the instruction block, no explanation.

## The Problem

Ask for a unit test in a TypeScript repo and odds are good you'll get Jest — `jest.mock()`, `jest.fn()`, Jest config assumptions — even when `vitest` is sitting in `package.json` and every existing test file imports from `vitest`. Jest dominated the training data, so Jest is the reflex. The same reflex produces pytest fixtures in a `unittest` codebase, Mocha-style `done` callbacks in a Jasmine project, and JUnit 4 annotations in a JUnit 5 suite.

Sometimes the mismatch fails loudly: `jest is not defined`, and you lose a round-trip fixing imports. The expensive version fails quietly. Vitest deliberately tolerates a lot of Jest-flavored syntax, so a Jest-shaped test may run — with subtly wrong mock hoisting, timer semantics, or module-reset behavior. The test passes for the wrong reason, and a mocking bug gets enshrined as a green checkmark.

The project already answers this question three different ways: dependencies in the manifest, imports in existing test files, and the `test` script itself. The failure is never ambiguity. It's not looking.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Detect the Test Framework Before Writing Tests

NEVER write a test until you have confirmed which test framework, runner, and assertion style this project actually uses. Your default (Jest, pytest, JUnit) is a statistic about other repos, not a fact about this one.

A wrong-framework test either fails on imports or — worse — runs under a compatible runner with subtly different mock and timer semantics.

**Before writing any test:**
- Check the manifest: `package.json` devDependencies and the `test` script, `pyproject.toml`, `Gemfile`, `build.gradle` — the runner is declared there
- Open one or two existing test files and copy their reality: import sources, describe/it vs test functions, fixture patterns, mock idioms, assertion library
- Match file naming and location conventions you observe (`*.test.ts` vs `*.spec.ts`, `__tests__/` vs colocated vs `tests/`)
- Check for framework config (`vitest.config.ts`, `jest.config.js`, `conftest.py`, `karma.conf.js`) before assuming defaults like globals or environment
- If the project has no tests yet and no framework installed, ask which one to use — don't install your favorite

**Red flags that you're about to violate this:**
- "I'll write this with Jest, it's the standard..."
- "Vitest is Jest-compatible, so the syntax doesn't matter..."
- "pytest is what everyone uses for Python now..."
- "I don't need to open the existing tests, tests all look the same..."
- "I'll add the testing library to package.json while I'm at it..."
- Typing `jest.mock` or `@pytest.fixture` before reading a single existing test file

---

## Why It Works

1. **It demotes the default to a statistic.** "Jest is the standard" is the exact rationalization that precedes the failure; reframing it as a fact about training data, not this repo, breaks its authority.

2. **It targets the compatibility trap specifically.** "Vitest accepts Jest syntax" is the loophole that lets wrong tests run. Naming the subtle semantic differences (mock hoisting, timers, module resets) makes "it ran" insufficient.

3. **It uses existing tests as the spec.** Copying observed imports and idioms is cheaper and more reliable than recalling framework documentation — the repo has already made every style decision.

4. **It blocks the uninvited install.** The worst version of this failure is the AI adding a second test framework to resolve its own mismatch. An explicit prohibition closes that exit.

## Origin

A team asked for tests around a date-handling module. The AI produced Jest tests using `jest.useFakeTimers()`; the project ran Vitest, which accepted the file but handled fake timers differently, so two tests passed while exercising real time. Weeks later a timezone bug those tests "covered" hit production. The postmortem's most painful line: the test suite had been green the entire time.
