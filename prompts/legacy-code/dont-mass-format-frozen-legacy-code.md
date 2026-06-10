---
title: Don't Mass-Format Frozen Legacy Code
slug: dont-mass-format-frozen-legacy-code
category: legacy-code
tags: [universal, legacy]
works_with: all
severity: medium
one_liner: "Stops formatter sweeps that wreck blame and destabilize frozen modules"
---

# Don't Mass-Format Frozen Legacy Code

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from running formatters and lint autofixes across legacy modules, destroying git archaeology and injecting "safe" changes into code that's frozen for a reason.

**[Copy-paste ready version](../../install/dont-mass-format-frozen-legacy-code.md)** — just the instruction block, no explanation.

## The Problem

Give an AI assistant access to a codebase with inconsistent formatting and it will, sooner or later, propose the big one: run the formatter over everything, fix all lint warnings, one glorious normalization commit. On a young codebase, fine. On legacy modules, this commit is a triple hazard dressed as hygiene.

First, it nukes the archaeology. After a 4,000-line reformat, `git blame` on every one of those lines points to "apply prettier" instead of the commit that explains the code. For legacy modules — where blame is often the only surviving documentation — this burns the library to tidy the shelves. Second, lint autofixes are not all behavior-neutral: "fixes" that swap equality operators, remove "unused" variables with side effects, reorder imports that have load-order effects, or rewrite async patterns can each change runtime behavior, and a mass autofix applies hundreds of them unreviewed in code with no tests to object. Third, frozen modules are often frozen *deliberately* — pending deprecation, vendored from upstream (where reformatting destroys the ability to diff against new upstream releases), or under change-control because they're regulated or hotfix-only.

The team's formatting boundary usually exists in tool configs — ignore files, exclusion lists — that the AI overrides or never reads.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Don't Mass-Format Frozen Legacy Code

NEVER apply formatters or lint autofixes in bulk to legacy code, and never propose repo-wide normalization as cleanup. Mass-formatting frozen modules destroys git blame (often the only documentation old code has), applies unreviewed behavior-relevant "fixes" to untested code, and tramples deliberate freeze boundaries.

Rules of engagement:

- Respect the existing exclusion config absolutely: `.prettierignore`, `.eslintignore` equivalents, formatter exclusion lists, lint overrides per directory. An excluded path is a decision, not an oversight to correct.
- Never widen formatting beyond the lines you are editing. Touch a function, format that function if local convention says so; never let the editor or a save-hook reformat the whole file as a side effect of a one-line change.
- Treat lint autofix as code change, not formatting. Fixes that alter equality semantics, delete "unused" code, or reorder imports can change behavior; in untested legacy modules they are unreviewable risk applied at machine speed.
- Never reformat vendored or upstream-synced code. Reformatting it permanently breaks diffing against upstream, which is how that code gets updated.
- If repo-wide formatting is genuinely wanted, it's a project decision for the user: done in dedicated commits, with the formatting commit added to `.git-blame-ignore-revs` so blame survives, and with frozen or vendored paths excluded. Propose that — don't perform it.

**Red flags that you're about to violate this:**
- "While I'm here, I'll just run the formatter on the whole file."
- "Consistent formatting across the repo is an obvious win."
- "Lint autofixes are safe by definition."
- "This ignore file is probably just stale config."
- "The diff is big but it's all whitespace, nothing to review."
- "Old code deserves the same standards as new code."

---

## Why It Works

1. **It prices in the blame destruction.** The AI weighs formatting as aesthetics versus nothing; naming blame as legacy code's primary documentation makes the trade visible — and usually unacceptable.
2. **It splits formatter from autofixer.** The AI's safety intuition comes from whitespace-only formatters but gets applied to lint fixes that rewrite semantics; separating the categories removes the false license.
3. **Exclusion configs become contracts.** "An ignored path is a decision" converts the team's freeze boundaries from invisible config into rules the AI can locate and obey.
4. **The blame-ignore-revs escape hatch keeps the rule honest:** repo-wide formatting remains achievable, just as a deliberate project decision with the damage-control steps included, rather than a drive-by.

## Origin

An assistant asked to fix one lint warning ran the autofixer across a legacy billing module excluded from linting since the exclusion file was created. Among four hundred mechanical changes, the autofixer removed an "unused" variable assignment whose getter call lazily initialized a connection pool, and converted loose equality checks that had been quietly coercing string IDs from an old database driver. Two subtle production bugs took a combined three weeks to trace — partly because `git blame` on every affected line now pointed to a commit titled "fix lint warnings," which is also why the module had been excluded in the first place.
