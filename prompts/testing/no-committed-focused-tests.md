---
title: No Committed Focused Tests
slug: no-committed-focused-tests
category: testing
tags: [universal, testing]
works_with: all
severity: critical
one_liner: "Leftover .only and fdescribe silently reducing the suite to a handful of tests"
---

# No Committed Focused Tests

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents leftover test-focus markers that make the runner silently ignore everything else.

**[Copy-paste ready version](../../install/no-committed-focused-tests.md)** — just the instruction block, no explanation.

## The Problem

While iterating on one stubborn test, the AI does the sensible thing: `it.only('handles refunds', ...)` to stop wading through the full suite's output. The test gets fixed. The `.only` does not get removed. From that commit forward, the file contributes exactly one test to every run — the other thirty-four still exist, still look like coverage in the source, and are never executed. `fdescribe` is the bulk version, focusing a whole block and benching every other block in the file. The runner doesn't fail, doesn't warn loudly, and the output still says PASS, because the one anointed test does pass.

This is the inverse of skipping with the same outcome: instead of marking tests off, everything unmarked goes dark. It's nastier than a skip because the surviving green is so reassuring — the file ran, the suite passed, the count being mysteriously low is a detail nobody audits. AI assistants leave focus markers behind because the marker did its job during debugging and removing it is a cleanup step with no failing signal to prompt it; the suite is green either way, just thirty-four tests lighter in one case.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No Committed Focused Tests

NEVER leave a focus marker — `.only`, `fit`, `fdescribe`, `test.only`, `describe.only`, `it.focus`, or any equivalent — in test code you deliver. A focused test doesn't run one test extra; it stops every other test from running, silently.

The core problem: focus markers are debugging tools whose effect outlives the debugging. One leftover `.only` converts a 35-test file into a 1-test file while the runner keeps printing PASS.

Rules:
- Focus markers are fine while actively iterating; preferable is the runner's filter flag instead (`jest -t "handles refunds"`, `pytest -k refunds`, `--grep`), which narrows the run without editing the file and therefore cannot be committed
- Before declaring any test work done, sweep for focus markers in everything you touched: search for `.only(`, `fit(`, `fdescribe(`, `focus`, and your framework's equivalents. This sweep is part of finishing, not optional polish
- After removing a focus marker, run the full file again — the tests you benched while focusing have not run against your final code, and "it passed" so far refers only to the focused one
- Compare test counts: if the file ran 1 test where it has 35, or the suite total dropped versus the baseline, find out why before reporting anything
- If you inherit a file that already contains someone's committed `.only`, flag it immediately — every test it benched has been unexecuted for an unknown number of commits, and they need a run before anyone trusts them
- Where the project has lint support, recommend enabling it (`no-focused-tests` in eslint-plugin-jest/mocha rules) so this class of leftover fails fast

**Red flags that you're about to violate this:**
- "The focused test passes now, task complete..."
- "I'll leave the .only since I might iterate more..."
- "The suite is green, so everything must have run..."
- "Removing the marker is cosmetic, I'll mention it instead of doing it..."
- "The other tests in this file were passing before, no need to rerun them..."

---

## Why It Works

1. **It reframes what `.only` does.** The AI parses it as "run this one," not "unplug everything else." Stating the subtractive effect — 35 tests become 1 — makes the leftover marker legible as the suite-wide outage it is.

2. **It catches the false done-signal.** The failure happens at the moment of completion, when the focused test passes and everything feels finished. Making the marker sweep part of the definition of done inserts the check exactly where the lapse occurs.

3. **It closes the post-removal gap.** Removing `.only` and not rerunning means the benched tests still haven't seen the final code. Requiring the full rerun addresses the subtle second failure hiding behind the obvious first one.

4. **It steers toward filter flags.** `-t`/`-k` narrowing gives the identical debugging benefit with no file edit to forget — substituting an uncommittable tool for a committable hazard.

## Origin

A payments test file with 40 tests shipped with an `fdescribe` around its three refund tests — left by an assistant that had focused the block while fixing one of them. For seven weeks, every CI run executed 3 of the 40 and reported the file passing. Among the 37 dark tests were the card-decline cases, one of which regressed during those weeks: declined cards were marked paid. The regression was found by the finance team's reconciliation, not the suite, and the cleanup commit consisted of deleting nine characters.
