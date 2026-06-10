---
title: Rerun Checks Instead of Trusting Old Results
slug: rerun-checks-instead-of-trusting-old-results
category: context
tags: [universal, staleness, verification]
works_with: all
severity: high
one_liner: "AI declaring 'tests pass' based on a run from before the last five edits"
---

# Rerun Checks Instead of Trusting Old Results

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from citing test, build, and lint results that predate the changes made since.

**[Copy-paste ready version](../../install/rerun-checks-instead-of-trusting-old-results.md)** — just the instruction block, no explanation.

## The Problem

Twenty minutes ago the suite was green. Since then: three file edits, a renamed function, an import shuffle. The session ends with "all tests pass" — citing that twenty-minute-old run as if it covered code it never saw. Verification results are facts about a specific snapshot of the code; the AI treats them as facts about the project, durable across any number of subsequent edits. "I ran the tests" quietly becomes "the tests pass," tense and snapshot lost in translation.

This is how broken code ships with a verification narrative attached. The user reads "build succeeds, tests green, lint clean" and reasonably believes those claims describe the final state of the diff — but the build ran before the last edit, the tests before the refactor, lint never. The gap is invisible in the summary precisely because the AI isn't lying — it *did* run those checks. They just verified a codebase that no longer exists.

The rule is the same one human engineers learn from their first embarrassing "but it passed locally": the last thing you do before declaring done is run the checks again, on the actual final state.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Rerun Checks Instead of Trusting Old Results

NEVER report a test, build, lint, or typecheck result that predates your most recent code change. A green run is a fact about the exact code it ran against — every subsequent edit resets it to "unknown," no matter how small the edit.

Stale results don't read as stale in a summary: "tests pass" sounds like a property of the final diff even when it describes a snapshot from five edits ago.

**Operating rules:**
- Any edit after a check invalidates that check — including "trivial" ones: renames, import changes, comment-adjacent formatting, the one-line fix you made after the suite went green
- Before declaring work complete, run the relevant checks once more against the final state; this final run is the only one your summary may cite
- Report results with their snapshot scope when work continued afterward: "tests passed before the last rename; not re-run since" — never an unqualified "tests pass"
- The same applies to failure states: a bug you "reproduced" before several fixes may be gone — re-verify before continuing to fix it (and before claiming you fixed it)
- Don't extrapolate across scope: a passing unit suite from earlier says nothing about the build; each check covers what it covers, when it ran
- If rerunning is impossible (no environment, suite too slow), say explicitly which checks are stale rather than letting an old green stand in for a current one

**Red flags that you're about to violate this:**
- "Tests passed earlier, and my last change was tiny..."
- "It's just a rename, nothing behavioral..."
- "I already verified this, no need to repeat it..."
- "The build was fine ten edits ago, so..."
- "I'll mention the green run from before — close enough..."
- Writing "all checks pass" when the most recent check predates the most recent edit

---

## Why It Works

1. **It gives results an expiration trigger.** "Every edit resets the check to unknown" replaces the fuzzy judgment ("was my change big enough to matter?") with a mechanical rule that small-change rationalizations can't erode.

2. **It targets the tense-shift.** "I ran the tests" mutating into "the tests pass" is the precise linguistic move that ships stale claims; naming it makes the AI notice the mutation mid-summary.

3. **It covers stale failures too.** Continuing to "fix" an already-fixed bug wastes sessions just as stale greens ship bugs; symmetry closes the other half of the staleness problem.

4. **It provides the honest degraded mode.** When rerunning truly isn't possible, scoped reporting ("passed before X, not since") preserves accuracy without demanding the impossible — removing the excuse for unqualified claims.

## Origin

An AI finished a feature, ran the suite — green — then noticed an unused import and "cleaned up" by removing it, along with what it judged to be a redundant re-export on the same line. Summary: "implemented, all tests passing." The re-export was load-bearing for a sibling package whose tests would have caught it instantly, on the run that never happened. The breakage surfaced two days later in a teammate's branch, and the archaeology pointed back to a commit whose message confidently said "tests: all green."
