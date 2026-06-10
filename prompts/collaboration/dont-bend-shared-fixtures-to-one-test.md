---
title: Don't Bend Shared Fixtures to One Test
slug: dont-bend-shared-fixtures-to-one-test
category: collaboration
tags: [universal, teamwork, testing]
works_with: all
severity: medium
one_liner: "Stops editing shared fixture data to suit one test, skewing all the others"
---

# Don't Bend Shared Fixtures to One Test

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from editing shared fixture and seed data to make one test pass, changing what every other test that reads that data verifies.

**[Copy-paste ready version](../../install/dont-bend-shared-fixtures-to-one-test.md)** — just the instruction block, no explanation.

## The Problem

Shared fixtures — the `fixtures/users.json`, the seed SQL, the canonical `sample_order` object, the recorded API payload a dozen suites load — are data many tests read and one file defines. The AI, writing a test that needs a user with three orders, finds the fixture user has two and simply edits the file: adds an order, flips a status to the one it needs, bumps a date that was making things awkward, changes an amount to a rounder number. Its test passes. Every other test reading that fixture is now running against different data than its author wrote it for.

Fixture edits propagate differently than code edits — through assumptions instead of call graphs. A test asserting "total equals 150.00" fails loudly, which is the lucky case. The unlucky case: tests that depended on the data's *properties* without asserting them — the user having no refunds, the date being in the past, the amounts straddling a discount threshold — keep passing while no longer exercising the scenario they were written to cover. The fixture was a shared premise, and the AI changed the premise mid-argument. Multiply across a few such edits and the fixture set drifts into incoherence: data that satisfies the union of every test's convenience and the intent of none.

The AI does this because the fixture file is sitting right there, editing it is one change instead of building new data, and the data looks arbitrary. It isn't. Every odd-looking value in a mature fixture is load-bearing for a test the AI hasn't read.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Don't Bend Shared Fixtures to One Test

NEVER edit shared fixture or seed data to fit the test you're writing. Shared fixtures are premises that many tests rely on; changing a value changes what all of them verify, usually without failing any of them.

Assume every value in a mature fixture is load-bearing for a test you haven't read — the weird date, the specific amount, the missing field are usually someone's scenario.

- Need different data? Add it: a new fixture entry, a new record in the seed, a factory call with overrides in your own test's setup. Additive changes can't change anyone else's premise.
- Never modify existing entries' values, flip statuses, change quantities, or "fix" odd-looking data in shared fixtures. Oddness is often the point.
- Don't delete fixture entries your tests don't use; your usage isn't the usage.
- Don't normalize, reformat, or re-sort fixture files in passing — recorded payloads and seed dumps may be compared byte-wise or position-wise somewhere.
- If an existing fixture value is genuinely wrong (violates the schema, contradicts what it claims to represent), fix it as its own change, run every suite that loads the fixture, and say what you changed and why.
- When adding entries, keep them clearly named and scoped (e.g., `user_with_three_orders`) so the next person can tell which premise belongs to whom.

**Red flags that you're about to violate this:**
- "I'll just give this fixture user one more order; it's close to what I need."
- "This status should be 'active' for my test; quick edit."
- "These dates are stale; I'll bring them up to date."
- "Nobody could care about this exact amount."
- "Adding a whole new fixture entry for one test feels wasteful."

---

## Why It Works

1. **It distinguishes additive from mutative**: new entries have zero readers and thus zero blast radius, while edits propagate through every test's unstated assumptions — the rule channels need into the safe direction.
2. **It flips the presumption about odd data**: in mature fixtures, weird values are evidence of intent, not errors, and the rule makes them protected by default instead of cleanup targets.
3. **It catches the silent case**, where tests pass against changed premises and quietly stop covering their scenario — undetectable by CI, preventable only at edit time.
4. **It legitimizes real fixes with a protocol** (own change, run all loading suites, announce), so actual data bugs still get corrected without each correction being a stealth premise change.

## Origin

A shared seed file contained an account with a balance of exactly 0.00 — created, though the file didn't say so, to cover a division-by-zero guard in interest calculation. An assistant needing a "typical" account changed the balance to 1,000.00 rather than add a new entry. The interest tests kept passing; they asserted no errors, and with a nonzero balance there were none to guard against. The zero-balance code path went uncovered for five months until a real customer with an empty account hit the exact crash the original fixture had been built to prevent.
