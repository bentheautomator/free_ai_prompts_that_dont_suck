---
title: No Duplicate Test Names
slug: no-duplicate-test-names
category: testing
tags: [universal, testing]
works_with: all
severity: high
one_liner: "AI appending a test whose name shadows an existing one, silently erasing it"
---

# No Duplicate Test Names

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from adding a test that redefines an existing name, making the original silently stop existing.

**[Copy-paste ready version](../../install/no-duplicate-test-names.md)** — just the instruction block, no explanation.

## The Problem

In Python, a file is executed top to bottom, and a second `def test_validates_email():` doesn't conflict with the first — it *replaces* it. No error, no warning by default, no skipped count. The original test, possibly the one guarding a subtle bug, simply ceases to be collected, and the suite's total quietly stays the same or drops by one in a count nobody memorized. The same shadowing hits class-based tests (`def test_update` twice in one TestCase), and JS isn't immune: two `it('validates email')` blocks both run, but reporters, `--testNamePattern` filters, and snapshot keys now point at an ambiguous name — and a later "deduplication" cleanup deletes whichever one someone judges redundant by its title.

AI assistants create duplicates because they append. Asked to "add a test for email validation," the model writes the obvious function with the obvious name at the end of the file — and the obvious name is obvious precisely because someone already used it. In long files, the existing test sits outside whatever portion the AI actually read. The result is uniquely sneaky: the diff shows only an addition, green stays green, and a previously-passing test has been deleted without any deletion appearing anywhere.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No Duplicate Test Names

NEVER add a test whose name already exists in the same file or class. In Python, the new definition silently replaces the old one — adding a test can delete a test, with no error and no diff line showing the loss.

The core problem: appending is how tests get added, and natural names collide. A shadowed test stops being collected entirely; the suite stays green because the alarm wasn't triggered — it was unplugged.

Rules:
- Before adding a test, search the file (and its class) for the name you're about to use — and for the behavior you're about to cover. Grep the test name; don't trust that you'd have noticed
- If the name exists, first decide whether the existing test already covers your case. The right move may be extending it or adding a distinct case, not writing a near-twin
- If you genuinely need a new test of similar intent, differentiate the name by what's different about the case: `test_validates_email_rejects_missing_at` vs `test_validates_email_accepts_subdomains` — specific names prevent the next collision too
- After adding tests, verify the collected count went UP by the number you added (`pytest --collect-only -q | tail`, compare runner totals). Same count after adding two tests means something got shadowed
- In JS/parameterized frameworks, the same discipline applies to `it()` descriptions and parametrize IDs: duplicate names break filters, reporters, and snapshot keys even when both tests run
- When you find an existing duplicate pair, flag it — one of them has been dead, and which one matters

**Red flags that you're about to violate this:**
- "I'll add the new test at the bottom, the natural name is test_validates_email..."
- "This file is huge, I'll just append without reading the whole thing..."
- "The diff is purely additive, so nothing can have been lost..."
- "If a name collided, the runner would error..."
- "Test counts bounce around anyway, no need to compare totals..."

---

## Why It Works

1. **It corrects a false mental model of the runtime.** The AI assumes a name collision would error — most don't. Stating plainly that Python redefinition is silent replacement converts "the runner would tell me" from an assumption into a known falsehood.

2. **It breaks the purely-additive illusion.** A diff showing only green plus-lines feels incapable of removing coverage. Naming the mechanism — addition-as-deletion — is exactly the non-obvious fact the AI needs at append time.

3. **It adds an arithmetic verification.** Collected-count-before vs. after is a cheap, mechanical check that catches shadowing regardless of whether the search step was done well. Two independent layers beat one.

## Origin

A validation module's test file had grown to 1,900 lines, and an assistant asked to "add coverage for the new domain rules" appended `def test_validates_domain` — a name first used 1,400 lines earlier on the test covering punycode handling. The original silently stopped being collected; the suite count went from 212 to 212 and nobody compared. The punycode regression it had been guarding shipped a quarter later, and the eventual investigation found the dead test still sitting in the file, looking for all the world like coverage.
