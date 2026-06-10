---
title: Bisect the Regression, Don't Guess It
slug: bisect-the-regression-dont-guess-it
category: debugging
tags: [universal, debugging, root-cause]
works_with: all
severity: high
one_liner: "AI guessing at which change broke it when history can be bisected"
---

# Bisect the Regression, Don't Guess It

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from theorizing about which change broke working behavior when the history is sitting right there, bisectable.

**[Copy-paste ready version](../../install/bisect-the-regression-dont-guess-it.md)** — just the instruction block, no explanation.

## The Problem

"This worked last week" is the single most useful sentence in debugging, and AI assistants routinely throw it away. Told that a feature regressed, the assistant starts reading the current code for flaws — as if the bug were timeless — instead of exploiting the one fact that changes everything: a known-good state exists, a known-bad state exists, and a finite, ordered list of changes lies between them. Finding the culprit is a search problem with a logarithmic solution, not a theorizing problem.

The model skips bisection because it lives outside the code: it means running `git log` across the regression window, checking out or testing midpoints, and letting `git bisect` do the thinking. Reading the present-day code and nominating a suspicious-looking function feels more like engineering. But for a regression, code-reading is the slow path — the defect could be in any of 60 commits' worth of changes, and plausibility-based guessing examines them in the worst possible order: most-interesting-first instead of half-at-a-time.

The result is regression hunts that take afternoons instead of minutes, conclude with "probably this refactor" without confirmation, and occasionally "fix" code that was never the thing that changed.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Bisect the Regression, Don't Guess It

When something used to work and now doesn't, ALWAYS treat it as a search over history, not a fresh inspection of the current code. Establish known-good, establish known-bad, and bisect the changes in between.

A regression's cause is, by definition, in the diff between working and broken. That diff is finite and ordered; binary search finds the culprit in log(n) tests, while plausibility-guessing examines suspects in vibes order.

- First, pin the endpoints with actual runs: verify the reproduction fails now, and verify (or get confirmed) a specific commit/version/date where it passed — "it worked at some point" must become "it worked at <ref>"
- Use `git bisect` with the reproduction as the test where possible; with a scriptable check, `git bisect run` automates the whole search
- No runnable history? Bisect whatever you can: dependency versions, config changes, data snapshots, feature flags — the same halving logic applies
- When bisection lands on a commit, read that commit's diff to find the mechanism; the commit is the cause's address, not yet the explanation
- Do not start proposing code fixes based on "this area looks like it could cause it" while the bisection is unfinished — finish the search, then fix what it found
- If the endpoints can't be established (never actually worked, environment changed underneath), say so explicitly — that reclassifies the bug and changes the strategy

**Red flags that you're about to violate this:**
- "Looking at the current code, the likely cause of the regression is..."
- "The recent auth refactor is the obvious suspect, I'll start there..."
- "Bisecting would take a while; let me just check the big changes..."
- "It worked before, so something in this function must have changed..." (did you diff it?)
- Forming a theory about the breaking change without having run `git log` over the window
- "Fixing" code that the history shows hasn't changed since the known-good state

---

## Why It Works

1. **It reclassifies the problem type.** "Regression = search over a finite diff" replaces the AI's default frame of "bug = flaw to spot in code." Search problems trigger procedures; spotting problems trigger guesses.

2. **It forces real endpoints.** Half of failed regression hunts die on a mushy "used to work"; requiring a verified good ref converts folklore into a usable search boundary.

3. **It defers fixing until the search ends.** The mid-bisect "I see something suspicious" detour is the main way bisection gets abandoned; explicitly banning it keeps the log(n) guarantee intact.

4. **It separates address from mechanism.** "Bisect found commit abc123" is where, not why; requiring the diff-read step prevents reverting a commit wholesale when the actual fix is one line of it.

## Origin

A PDF generator started cutting off the last page, and an assistant spent a session inspecting the current rendering code, proposing three speculative fixes around page-size math — none of which were in code that had changed. A developer ran `git bisect` with a five-line script: eleven steps, nine minutes, landing on a dependency bump where the HTML-to-PDF library changed its default margin handling. The fix was one line in a config object. The afternoon of speculation had never had a chance of finding it, because the culprit wasn't in the repo's own code at all.
