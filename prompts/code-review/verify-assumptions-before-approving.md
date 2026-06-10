---
title: Verify Assumptions Before Approving
slug: verify-assumptions-before-approving
category: code-review
tags: [universal, review, verification]
works_with: all
severity: high
one_liner: "Stops approvals built on 'presumably the tests cover this' style assumptions"
---

# Verify Assumptions Before Approving

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents approving a PR while load-bearing claims — "tests cover this," "callers handle null," "this matches the old behavior" — remain unchecked guesses.

**[Copy-paste ready version](../../install/verify-assumptions-before-approving.md)** — just the instruction block, no explanation.

## The Problem

Ask an assistant to review a PR and you'll often get an approval whose reasoning, if written out honestly, reads: "The logic looks correct, presumably the existing tests cover the changed path, the callers probably handle the new error type, and the migration is likely backwards compatible. LGTM." Every "presumably" is a thing the reviewer could have checked and didn't. The approval is a stack of unverified premises with a green checkmark on top.

This is the natural failure shape of a language model doing review: it's superb at generating plausible reasons code is fine and has no built-in pressure to test those reasons against the repo. Checking whether tests actually exercise the changed branch means opening test files, grepping for callers, reading the old implementation — work that's available but not demanded by the act of writing "LGTM."

The result is an approval that means "nothing looked wrong from here," delivered with the authority of "I checked." Humans downstream can't tell the difference, and the PR merges carrying every assumption that happened to be false.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Verify Assumptions Before Approving

NEVER approve a PR while your reasoning contains an unverified load-bearing claim. If your approval depends on something being true, either check it in the repo or state it as an open question — an assumption you could have verified and didn't is not a review, it's a guess with formatting.

- Before approving, list what your "this is fine" actually depends on. Common load-bearing assumptions: "tests cover the changed path," "all callers handle the new return value," "this constant isn't used elsewhere," "the old code did the same thing," "this config exists in prod."
- Each one gets resolved one of three ways: verify it (open the test file, grep the callers, read the old code), ask the author to confirm it, or write it into the approval as an explicit unchecked condition: "Approving assuming X — I did not verify it."
- "The diff looks correct" only covers the diff. Claims about everything outside the diff — callers, tests, config, history — are exactly the ones that need checking, because the diff can't show them.
- If verification is impossible from where you sit (no access to prod config, can't run the suite), say so and downgrade your approval to a comment. Don't let the approval imply checks you couldn't perform.
- Time spent: grepping callers takes a minute. The bug you'd have caught takes a sprint.

**Red flags that you're about to violate this:**

- "Presumably the test suite would catch it if this were wrong..."
- "The author surely checked the callers when they changed the signature..."
- "It compiles, so the interface changes must be consistent..."
- "This pattern is used elsewhere in the codebase, so it must be safe here..."
- "Checking would mean reading three more files, and the diff itself looks clean..."
- "CI is green, which probably means the behavior is covered..."

---

## Why It Works

1. **Listing dependencies converts vibes into checkable items.** The approval can't be assembled from plausibility once the model must enumerate what it rests on — each item either gets verified or gets visibly flagged.
2. **Three dispositions, none of them silent.** Verify, ask, or disclose. The unavailable move — quietly assuming — is the entire failure mode, and the rule removes it from the menu.
3. **It targets the diff's blind spot by name.** Most false assumptions live outside the diff (callers, tests, config). Stating that the diff can't testify about them tells the model exactly where its confident feeling is least grounded.
4. **Disclosed assumptions keep the human in the loop.** "Approving assuming X" lets the author or a second reviewer cheaply confirm X — the check happens somewhere, instead of nowhere.

## Origin

An assistant approved a PR that changed a date-parsing helper, noting the change was "safe since existing tests pin the parsing behavior." The test file it never opened contained one test, skipped since a flaky-test purge two years earlier. The helper silently shifted timezone handling, every scheduled report in a non-UTC region fired at the wrong hour, and the postmortem's root-cause line read: "reviewer assumed test coverage that did not exist."
