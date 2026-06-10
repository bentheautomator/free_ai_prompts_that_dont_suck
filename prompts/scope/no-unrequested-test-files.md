---
title: No Unrequested Test Files
slug: no-unrequested-test-files
category: scope
tags: [universal, scope]
works_with: all
severity: medium
one_liner: "AI shipping a small fix with an unrequested 300-line test suite attached"
---

# No Unrequested Test Files

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from bolting full test suites, fixtures, and mock infrastructure onto a request that didn't include them.

**[Copy-paste ready version](../../install/no-unrequested-test-files.md)** — just the instruction block, no explanation.

## The Problem

You ask for a ten-line change and get the change plus three new test files: a parametrized suite covering twelve cases, a fixtures module, a mock factory, and a conftest amendment. Nobody asked. Now the review is 90% tests of behavior nobody specified, and the team owns 300 new lines of maintenance whose assumptions were invented by the AI on the spot.

To be clear about what this prompt is not: tests are good, and a team whose process expects tests with every change should say so and get them. The failure here is unrequested test infrastructure as scope creep — the AI deciding unilaterally what the specification is and encoding its guesses as assertions. Generated tests freeze the AI's reading of intended behavior, including the parts it got wrong. When one of those guessed assertions fails next month, an engineer must reverse-engineer whether it encoded a requirement or a hallucination, and the safest-feeling move is to make code conform to the test, which is exactly backwards if the test was a guess.

There's also a practical distortion: the requested change becomes the smallest part of its own diff, and reviewer attention is spent where the AI chose, not where the user did.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No Unrequested Test Files

Write tests when the request, the visible project convention, or the user's standing instructions call for them. NEVER unilaterally attach test suites, fixtures, or mock infrastructure to a change that didn't ask for any.

The core problem: unrequested tests encode your guesses about intended behavior as permanent assertions, and the team inherits maintenance of a specification nobody wrote.

- If the request says "fix X," deliver the fix; do not append new test files, fixture modules, mock factories, or test-config changes on your own initiative
- If the project visibly requires tests with changes (existing convention, CI gates, contribution docs), follow that; convention is a real instruction
- Updating an existing test that your change legitimately breaks is in scope and required; that is keeping the build green, not creep
- When asked for tests, test the requested behavior; do not expand into testing neighboring functions the task didn't touch
- Never grow shared test infrastructure (conftest, global fixtures, test utilities) to support tests nobody requested
- If you believe the change is risky and untested, say so in one sentence and offer: "Want me to add tests for this?" An offer costs one line; an unrequested suite costs a review

**Red flags that you're about to violate this:**
- "I'll add a comprehensive test suite to go with this fix..."
- "Good engineering practice means shipping tests with every change..."
- "While writing one test, I'll cover the edge cases too..."
- "This module had no tests at all, I'll fix that..."
- "More test coverage is always welcome..."

---

## Why It Works

1. **It locates the authority for specifications.** Tests assert what code should do; the rule makes explicit that the AI doesn't get to author that contract uninvited, only to implement or verify one that exists.

2. **It distinguishes convention from initiative.** Projects that require tests still get them, because the rule names visible convention as a real instruction; only the unilateral case is banned.

3. **It keeps the build-green duty.** Explicitly requiring updates to legitimately broken existing tests prevents the rule from being misread as "never touch tests," which would cause worse failures.

4. **It prices the alternative.** "An offer costs one line" gives the AI a cheap compliant action with most of the perceived value of the suite, making compliance the attractive path.

## Origin

A two-line timezone fix arrived with 340 lines of new tests, including a fixture file modeling the team's user object incorrectly (it guessed at a field that didn't exist in production data). The suite passed, was merged with a skim, and the wrong fixture was then copied into four later test files as the canonical example. Unwinding the fictional field from the test suite took a refactoring ticket that outlived the quarter.
