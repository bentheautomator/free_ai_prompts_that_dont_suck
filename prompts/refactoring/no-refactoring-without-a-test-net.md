---
title: No Refactoring Without a Test Net
slug: no-refactoring-without-a-test-net
category: refactoring
tags: [universal, refactoring, testing]
works_with: all
severity: high
one_liner: "Stops restructuring of code that has no tests to prove behavior survived"
---

# No Refactoring Without a Test Net

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from restructuring code that has no test coverage, where "the refactor preserved behavior" is an unverifiable claim.

**[Copy-paste ready version](../../install/no-refactoring-without-a-test-net.md)** — just the instruction block, no explanation.

## The Problem

A refactor's only promise is that behavior didn't change, and the only way to keep that promise is to have something that checks behavior. AI assistants skip this dependency entirely. Pointed at an untested 300-line pricing module, an assistant will restructure it with total confidence and report that "behavior is preserved," a claim backed by nothing but the model's belief that its own edit was correct. There is no test to run, so nothing was run, so nothing is known.

The model behaves this way because it cannot feel the difference between verified and plausible. Its restructured code *looks* equivalent, and looking equivalent is the only evidence a language model natively has. Humans with no tests get nervous and tread carefully; models with no tests proceed at full speed.

The fix is the same one working programmers have used for decades: before refactoring untested code, pin its current behavior with characterization tests, including the weird outputs. Then refactor against that net. It turns "trust me" into "the suite passed before and after."

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No Refactoring Without a Test Net

NEVER refactor code that has no test coverage of the behavior you're about to restructure. Without tests, "behavior preserved" is an unverifiable claim, and unverifiable claims about refactors are how production breaks.

- Before any refactor, identify the tests that exercise the target code and run them. They are your before/after oracle.
- If no tests cover it, STOP. Tell the user, and offer to write characterization tests first: tests that capture what the code *currently does*, including odd or apparently wrong outputs. Pin current behavior; do not pin your opinion of correct behavior.
- Characterization tests should cover the inputs that matter: typical cases, boundary values, empty/null inputs, and any branch the refactor will restructure. They don't need to be exhaustive, but every branch you intend to reshape needs at least one pin.
- Run the new tests against the *unmodified* code first and confirm they pass. A characterization test that fails on the original code is pinning the wrong thing.
- Only then refactor, and run the suite after each step.
- If the user explicitly declines tests and orders the refactor anyway, proceed in the smallest possible steps, state in your summary that the refactor is unverified, and list the behaviors most at risk.

**Red flags that you're about to violate this:**

- "The change is simple enough that tests aren't really necessary."
- "I can verify equivalence by reading both versions carefully."
- "Writing tests first would double the size of this task."
- "The type checker passing is effectively a test."
- "I'll refactor now and we can add tests later."

---

## Why It Works

1. **It exposes the unverifiable claim.** The model habitually reports "behavior preserved" with no oracle; the rule makes it confront that without tests, that sentence is decoration.
2. **Characterization framing prevents a second failure.** Told merely to "write tests first," models write tests for what the code *should* do, then "fix" the code to match, changing behavior. "Pin what it currently does, even the weird parts" blocks that swap.
3. **The pass-against-original check validates the net itself.** It catches the case where the model's tests encode its assumptions rather than reality, before those assumptions get baked into the refactor.
4. **The decline path keeps risk visible.** When the user overrides, the model must still narrow the steps and disclose the gap, so the decision to go unverified stays with the human.

## Origin

A contractor asked an assistant to clean up an untested freight-class lookup before adding a feature. The assistant restructured it and reported behavior preserved. It had collapsed two nearly identical branches that differed only in a rounding direction, a difference that existed because one carrier rounds weight up and another rounds to nearest. No test existed to object. The mispriced shipments were discovered at month-end reconciliation, and the cleanup that took ten minutes took two days to unwind.
