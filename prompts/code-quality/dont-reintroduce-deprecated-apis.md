---
title: Don't Reintroduce Deprecated APIs
slug: dont-reintroduce-deprecated-apis
category: code-quality
tags: [universal, apis, patterns]
works_with: all
severity: high
one_liner: "AI writing the old API back into a codebase that already migrated off it"
---

# Don't Reintroduce Deprecated APIs

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from undoing migrations by writing the deprecated pattern back into code that moved on.

**[Copy-paste ready version](../../install/dont-reintroduce-deprecated-apis.md)** — just the instruction block, no explanation.

## The Problem

The team spent a quarter migrating off `componentWillMount`, or from `moment` to `date-fns`, or from the ORM's legacy query API to the new one. The codebase is clean. Then an AI session adds a feature — and writes the old API back in, because the old API dominates its training data by sheer historical volume. Models have seen a decade of `componentWillReceiveProps` and eighteen months of the replacement; when generating from priors, the past outvotes the present.

This failure has a special sting: it's *regression by addition*. Every reintroduction reopens a fight the team already won — another deprecation warning in the console the team had finally silenced, another import of the library being removed (which keeps it pinned in the bundle and the dependency tree), another example of the old pattern for the next contributor to copy. Migration efforts die exactly this way: not reverted, but diluted, one fresh instance of the old pattern at a time, until "we migrated off X" is no longer a true sentence and the cleanup project restarts from a worse position than it started the first time.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Don't Reintroduce Deprecated APIs

NEVER write a pattern or API into a codebase that the codebase has migrated away from. Your training data over-represents the past; this repo lives in its present. The current pattern in the code outranks the common pattern in your memory.

Every reintroduction is regression by addition: it reopens a finished migration, re-pins a library being removed, and plants a fresh example of the old way for others to copy.

**Before using any API, library, or pattern:**
- Check what the codebase currently does for this need — and weight *recent* code most heavily. If new files all use the new ORM API and only old files use the legacy one, the legacy one is off-limits to new code
- Look for explicit migration signals: deprecation comments, lint rules banning specific imports (`no-restricted-imports`), `MIGRATION.md`/ADR notes, a "deprecated" directory, wrapper modules that adapt old to new
- A library being present in the dependency tree is not endorsement — it may be mid-removal. If two libraries that do the same job are both installed, find which one new code uses, and use that
- Same rule for language/framework idioms: class components in a hooks codebase, `var` in a `const`/`let` codebase, callbacks in a promises codebase — match the era the codebase has reached, not the era your training peaked in
- If you're unsure which of two observed patterns is current, ask — one sentence saves a reopened migration
- Heed deprecation warnings your code generates: a new warning from new code is this failure announcing itself

**Red flags that you're about to violate this:**
- "The classic way to do this is..."
- "moment.js handles this nicely..." (is it even the project's date library anymore?)
- "I've seen this pattern in thousands of projects..."
- "Both APIs work, so either is fine..." (one of them is being removed)
- "The old files do it this way..." (and the new files?)
- Writing a pattern you haven't confirmed appears in this codebase's *recent* code

---

## Why It Works

1. **It names the training-data skew.** The model can't feel that its priors are date-weighted toward the past. Stating "your memory over-represents the old API" gives it a reason to distrust exactly the patterns that feel most natural.

2. **It makes recency the tiebreaker.** Mid-migration codebases show both patterns, which reads as "either is fine." Weighting recent code resolves the ambiguity in the migration's favor every time.

3. **It decouples installed from endorsed.** "The library is right there in package.json" is the strongest false signal in this failure. Explicitly breaking the inference closes the loophole.

4. **It recruits migration artifacts as signals.** Lint bans, wrapper modules, and ADRs exist precisely to communicate "we left this behind" — the instruction teaches the AI to read them as the prohibitions they are.

## Origin

After a six-month effort to eliminate a legacy state-management library, a frontend team was down to four files and a removal ticket. Over the following month, AI-assisted feature work reintroduced the library's patterns into nine new components — it was still in `package.json` pending that final ticket, so the imports resolved fine and the model's training data did the rest. The removal ticket was quietly re-estimated from days to weeks, and the migration's champion described the burndown chart as "a sawtooth, emotionally."
