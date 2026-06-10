---
title: Finish git bisect With a Reset
slug: finish-bisect-with-a-reset
category: git
tags: [universal, git]
works_with: all
severity: medium
one_liner: "Stops abandoned bisects and good/bad mix-ups from wrecking sessions"
---

# Finish git bisect With a Reset

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from leaving a repo stranded mid-bisect or poisoning the search by mislabeling good and bad commits.

**[Copy-paste ready version](../../install/finish-bisect-with-a-reset.md)** — just the instruction block, no explanation.

## The Problem

`git bisect` is a stateful mode, not a one-shot command: it detaches HEAD and walks the repo through historical commits until you end it with `git bisect reset`. AI assistants start bisects competently and end them sloppily — or not at all. An abandoned bisect leaves the repository sitting on some commit from three months ago with HEAD detached; the next person (or the same AI, next task) edits files against ancient code, gets baffling test failures, or commits work onto a detached historical snapshot.

The other classic is label inversion. Bisect's terms trip everyone: marking the *old* commit `bad` and the *new* one `good` — easy to do when hunting a fix rather than a regression, or just when moving fast — sends the search in the wrong direction and produces a confident, wrong answer. The AI then reports an innocent commit as the culprit, and someone "fixes" code that was never broken. Bisect automates the search, not the bookkeeping; the bookkeeping is the part assistants flub.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Finish git bisect With a Reset

Every `git bisect start` must end with `git bisect reset` in the same task — no exceptions, including when the bisect is interrupted, errors out, or finds its answer early. Bisect is a mode: until reset, the repo sits detached on an arbitrary historical commit.

- Before starting, confirm the tree is clean (`git status`); bisecting with uncommitted changes mixes them into every checkout.
- Get the labels right before the first mark: `bad` = the commit where the problem EXISTS (usually newer), `good` = where it does NOT (usually older). When bisecting for when something was *fixed*, the vocabulary inverts confusingly; use `git bisect start --term-new=fixed --term-old=broken` and matching terms instead of forcing good/bad to mean their opposites.
- Verify both endpoints empirically before trusting them: actually run the test at the alleged good commit and the alleged bad one. A wrong endpoint silently produces a wrong answer with full confidence.
- Prefer automation where a command can decide: `git bisect run <test-command>` removes per-step labeling errors entirely.
- When bisect names a first-bad commit, sanity-check it: `git show <sha>` — does the change plausibly relate to the symptom? Then `git bisect reset` before doing anything else, including writing your report.
- If you find a repo already mid-bisect (`git status` mentions bisecting, or `.git/BISECT_LOG` exists), reset it before normal work.

**Red flags that you're about to violate this:**

- "Found the culprit; let me investigate it right from here."
- "The bisect crashed, so the mode probably cleared itself."
- "Good means the older commit, always."
- "I'll skip verifying the endpoints; the user told me where it broke."
- "I'll leave the bisect open in case we need to continue later."

---

## Why It Works

1. **Pairing start with reset as a single unit** treats cleanup as part of the operation rather than an afterthought — the same mechanism that makes "close your file handles" stick.
2. **The endpoint verification rule attacks the silent failure:** bisect on bad inputs doesn't error, it answers wrong with full confidence, so the only defense is testing the premises before the search.
3. **Recommending `--term-new/--term-old` for fix-hunting removes the semantic inversion** instead of asking the AI to hold "good means bad here" in its head across ten iterations.

## Origin

An assistant bisected a performance regression, correctly identified the commit, wrote an excellent analysis — and never ran `git bisect reset`. The user's next session began with the repo silently parked on a five-month-old commit; their first hour was spent debugging "missing" features that were simply newer than the checkout. The analysis was right; the repo was a time machine nobody knew they were standing in.
