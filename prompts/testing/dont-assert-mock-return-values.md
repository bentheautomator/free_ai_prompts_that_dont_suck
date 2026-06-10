---
title: Don't Assert Mock Return Values
slug: dont-assert-mock-return-values
category: testing
tags: [universal, testing, mocking]
works_with: all
severity: high
one_liner: "Tests that stub a value, receive it back, and assert it arrived"
---

# Don't Assert Mock Return Values

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents round-trip tests that configure a mock to return X and then triumphantly assert X.

**[Copy-paste ready version](../../install/dont-assert-mock-return-values.md)** — just the instruction block, no explanation.

## The Problem

Read this test slowly:

```javascript
userService.getUser = jest.fn().mockResolvedValue({ name: 'Alice', tier: 'gold' });
const profile = await buildProfile('alice-id');
expect(profile.name).toBe('Alice');
expect(profile.tier).toBe('gold');
```

If `buildProfile` does nothing but pass the mock's output through, this asserts that data you injected came back out — a property of the mock, not the code. The test would keep passing if `buildProfile` lost its validation, its enrichment, its error handling, or anything else it was presumably written to do. The only behavior actually pinned down is "returns whatever getUser returns," which is true of a one-line passthrough and possibly nothing else.

AI assistants generate this shape constantly because it produces real-looking assertions with concrete values that always pass. The mock setup supplies expected values for free — no spec reading required — and the assertions echo them. The result looks like a thorough test (look at all those specific expectations!) while exerting zero pressure on the unit's actual logic. The variant flavors: asserting that the value a mock was *called with* equals the variable you called it with, or asserting fields the code copies verbatim from input to output.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Don't Assert Mock Return Values

NEVER write assertions that merely confirm a mock's configured return value came back out. A test must assert something the code under test *did* — a transformation, a decision, a computation — not data you injected echoing back.

The core problem: asserting injected data round-tripped verifies the mock framework and a passthrough. It exerts no pressure on the unit's actual logic and passes even if all of that logic is deleted.

Rules:
- For each assertion, trace the asserted value backward. If it flows unmodified from a `mockReturnValue`/`mockResolvedValue`/`when(...).thenReturn(...)` into the expectation, the assertion is circular — replace it
- Assert the deltas: what did the code add, compute, filter, reformat, or decide? If the mock returns `tier: 'gold'`, assert the discount the code derived from gold, not the word "gold"
- Design stub data so passthrough would be distinguishable from correct processing — if the function should uppercase names, stub a lowercase name
- Asserting *call arguments* is legitimate when the code constructed them (`expect(api.charge).toHaveBeenCalledWith(4250)` where 4250 was computed); it's circular when you're checking your own input echoed through
- If you find there is no delta — the function genuinely just forwards the value — say so: the honest conclusion may be that this unit needs no test, or that the test belongs at a different level
- Self-check: would this test fail if the function body were `return await userService.getUser(id)`? If not, you haven't tested your code yet

**Red flags that you're about to violate this:**
- "The mock returns Alice, so I'll assert the result is Alice..."
- "Specific value assertions make this test strong..."
- "I'm verifying the data flows through correctly..."
- "Asserting the fields match the mock proves integration works..."
- "Every field checked — this test is thorough..."

---

## Why It Works

1. **It gives a mechanical circularity check.** "Trace the asserted value to its source" turns a fuzzy smell into a concrete audit: mock-to-expectation flow with no transformation equals no test. The AI can run this on its own output.

2. **It redirects attention to deltas.** The question "what did the code add or decide?" points the AI at the unit's actual responsibilities, which is where assertions belong and where the AI's default process never looks.

3. **It weaponizes stub design.** Choosing stub data that *exposes* passthrough (lowercase in, uppercase expected out) converts the mock from an answer key into a probe — the same setup effort, pointed in a useful direction.

## Origin

A profile-rendering module had 23 passing tests, written by an assistant, each stubbing the data layer and asserting the stubbed fields appeared in the output. A refactor accidentally dropped the step that masked email addresses for non-owners. Every test passed — masking was a delta, and no test asserted a delta; they asserted the stub's fields, which round-tripped fine. Unmasked emails were visible on public profiles for eleven days.
