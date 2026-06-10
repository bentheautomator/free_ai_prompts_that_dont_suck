---
title: Verify the Failure Path Not Just the Happy Path
slug: verify-the-failure-path-not-just-the-happy-path
category: verification
tags: [universal, verification, edge-cases]
works_with: all
severity: high
one_liner: "Calling error handling 'verified' when only the success case ever ran"
---

# Verify the Failure Path Not Just the Happy Path

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the assistant from declaring error handling verified when every check it ran was a success case.

**[Copy-paste ready version](../../install/verify-the-failure-path-not-just-the-happy-path.md)** — just the instruction block, no explanation.

## The Problem

An assistant adds a feature with retry logic, input validation, and a fallback branch. It runs the feature once with clean input, sees the expected output, and reports: "Implemented and verified, including error handling." The error handling has executed zero times. The retry was never triggered, the validation never saw bad input, the fallback never fell back. Half the deliverable is unverified and the report doesn't distinguish that half from the other.

Assistants default to this because the happy path is the cheap path: valid input is sitting right there, and constructing a failure — a timeout, a malformed payload, a missing file — takes deliberate setup. Verifying success once produces a satisfying green result that feels like it covers the whole change. Saying "verified" about all of it costs nothing in the moment.

The consequence surfaces at the worst time by definition: failure paths only run when something is already going wrong. That's when you discover the catch block references an undefined variable, the validation error crashes instead of returning 400, or the fallback recurses forever. Untested error handling routinely fails harder than the error it was meant to handle.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Verify the Failure Path Not Just the Happy Path

NEVER claim error handling, validation, retries, or fallbacks are verified unless you deliberately triggered the failure they handle and observed the handling behave correctly. A success-case run verifies the success case and nothing else.

The core problem: failure paths only execute when something goes wrong, so a normal run leaves them at zero executions. "Verified" after a happy-path run silently excludes exactly the code that runs during incidents.

- For every error branch you wrote or touched, force it to run: pass invalid input, point at a nonexistent file, kill the dependency, mock the timeout, raise the exception. Then observe what actually happens.
- Verify the handling itself, not just that something happened: the right error message, the right status code, the right cleanup, no secondary crash inside the handler.
- If a failure is genuinely hard to trigger (third-party outage, rare race), say so explicitly: "happy path verified; the timeout branch is untested because I cannot simulate the outage here."
- Scope your claims. "Verified with valid input" and "verified including the malformed-input case" are different sentences; use the one your evidence supports.
- Validation deserves a rejection test: show one bad input being refused, not just one good input being accepted.

**Red flags that you're about to violate this:**
- "The main flow works, and the error handling is simple enough..."
- "Triggering that failure would take real setup, and it's a standard pattern..."
- "The catch block just logs and returns, nothing to test there..."
- "I'll mark it verified — edge cases are unlikely anyway..."
- "The validation mirrors the schema, so bad input is obviously rejected..."
- "It handled the case I imagined while writing it..."

---

## Why It Works

1. **It redefines "verified" as path coverage, not feature coverage.** The vague claim survives because "the feature works" feels true after one good run. Tying the word to "the branch I'm claiming executed" makes the gap visible to the model itself.

2. **It demands the failure be manufactured.** "Pass invalid input, kill the dependency" converts an abstract obligation into concrete actions, removing the "no failure was available to test" excuse.

3. **It checks the handler for its own bugs.** Requiring observation of the handling — not just that an error occurred — catches the classic case where the recovery code is the thing that crashes.

4. **It offers a scoped-claim escape hatch.** When triggering the failure is truly impractical, the sanctioned move is a narrower claim, not a broader lie.

## Origin

A payment service gained a "graceful degradation" branch for when the fraud-check API was down. The assistant verified the integration with the API up, reported the degradation path as part of the verified work, and the PR merged. Weeks later the fraud API had a real outage, the degradation branch ran for the first time ever, and a typo'd field name in the fallback threw on every transaction — turning a partial outage into a total one. The branch had been "verified" in exactly the sense that it existed.
