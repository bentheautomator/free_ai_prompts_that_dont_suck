---
title: No Drive-By Docstring Pass
slug: no-drive-by-docstring-pass
category: scope
tags: [universal, scope, focus]
works_with: all
severity: medium
one_liner: "AI adding docstrings and comments to every function it walks past"
---

# No Drive-By Docstring Pass

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from blanketing untouched functions with docstrings and comments while doing unrelated work.

**[Copy-paste ready version](../../install/no-drive-by-docstring-pass.md)** — just the instruction block, no explanation.

## The Problem

A diff that was supposed to modify one function arrives having documented seven. Every function in the file now has a docstring — `"""Processes the data and returns the result."""` — plus inline comments narrating the obvious: `# increment the counter` above `count += 1`. The AI was in the neighborhood, and it documented the neighborhood.

Two things are wrong with this beyond diff bloat. First, generated docstrings on code the AI didn't write are guesses dressed as documentation. The AI infers intent from the implementation, so the docstring restates what the code does, not why — and where the inference is wrong, the project now contains confident, wrong documentation that future readers (and future AIs) will trust over the code. Second, comments are a maintenance liability with a known failure mode: they drift. Every narrating comment added today is a comment someone forgets to update tomorrow, and a stale comment is worse than none.

Documentation worth having is written deliberately, by someone who knows the intent, on the symbols that need it. It is a task, not a coat of paint applied to whatever file the AI happened to open.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No Drive-By Docstring Pass

Do not add docstrings or comments to code you are not otherwise changing. Document what you create; leave what you merely visited alone.

The core problem: docstrings generated for unfamiliar code are inferences presented as fact, and narrating comments are drift liabilities, so a documentation pass nobody asked for adds confident noise rather than knowledge.

- New functions, classes, or modules you write may carry documentation appropriate to the project's existing style and density
- Do not add docstrings to existing undocumented functions while passing through their file
- Do not add inline comments that restate code ("# loop over users" above a loop over users), in your code or anyone's
- Do not rewrite, "improve," or reformat existing comments and docstrings in code you aren't changing
- If you changed a function's behavior and its existing docstring is now wrong, updating that docstring is in scope and required; that is maintenance, not creep
- If you notice documentation that is absent where it's badly needed, or wrong in a way you can prove, mention it in one sentence instead of fixing it unasked

**Red flags that you're about to violate this:**
- "While I'm in this file, I'll document the other functions..."
- "Docstrings everywhere will help future maintainers..."
- "I'll add comments to make this section clearer..."
- "This codebase has poor documentation coverage, I can improve it..."
- "A quick docstring pass makes the diff more professional..."

---

## Why It Works

1. **It names the epistemics.** The AI treats its docstring as documentation; calling it "inference presented as fact" exposes that documenting unfamiliar code manufactures false authority, which is worse than absence.

2. **It draws the wrote-it/visited-it line.** "Document what you create" gives a crisp ownership boundary, replacing the fuzzy "document where helpful" that licenses blanket passes.

3. **It carves out the one required case.** Updating a docstring invalidated by your own change is genuinely in scope; stating it prevents the rule from being read as "never touch docs," which would cause a different failure.

4. **It bans the restating comment by example.** A concrete sample of the forbidden pattern is harder to rationalize around than an abstract "no unnecessary comments."

## Origin

An assistant asked to fix a date-boundary bug in one function also added docstrings to eleven others in the module. One docstring described a sampling function as returning "a uniformly random subset," which it deliberately did not — it was weighted, which was the point of the feature it served. Months later an engineer relied on the docstring instead of the code, built an analysis on the uniform assumption, and presented skewed results. The wrong docstring outlived everyone's memory of where it came from.
