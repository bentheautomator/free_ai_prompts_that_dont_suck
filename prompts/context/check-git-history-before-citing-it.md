---
title: Check Git History Before Citing It
slug: check-git-history-before-citing-it
category: context
tags: [universal, grounding, verification]
works_with: all
severity: high
one_liner: "AI inventing project history: refactors and decisions that never happened"
---

# Check Git History Before Citing It

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from narrating a project's past — refactors, migrations, authorship, intent — that it has no record of.

**[Copy-paste ready version](../../install/check-git-history-before-citing-it.md)** — just the instruction block, no explanation.

## The Problem

"This module was clearly refactored from an older class-based design." "This looks like it was added recently to patch the caching bug." "The team evidently moved away from REST here." These sentences narrate the project's history — and the AI saying them has read zero commits. It's reverse-engineering a plausible past from the present-day code, the way a geologist reads rock strata, except the geologist is hallucinating half the strata.

Invented history is uniquely corrosive because it explains things. "This weird check exists because of the old migration" satisfies the user's why-question and ends the investigation — with fiction. Decisions get made on top: code deemed "legacy, probably dead" gets deleted; a pattern described as "what they migrated away from" gets avoided; a workaround "added for a bug that's since been fixed" gets removed while the bug is alive and well. Each claim sounds like institutional memory. It's improv.

Unlike most hallucinations, this one has a complete, queryable counter-source sitting in `.git`. `git log`, `git blame`, and `git log -S` answer when, who, and what-changed with timestamps. There is no excuse to narrate when you can look.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Check Git History Before Citing It

NEVER make claims about this project's history — when code was added, why it changed, what it replaced, who touched it, what was "recently" modified — without checking the actual record. Inferring history from present-day code is fabrication with a confident narrative voice.

Invented history is dangerous because it *explains* things: it ends investigations and justifies deletions based on a past that never occurred.

**Before any historical claim:**
- Check the log: `git log --oneline -- <path>` for a file's actual timeline; `git log -S '<string>'` to find when specific code appeared or vanished
- Check authorship and age with `git blame <file>` before saying anything was added "recently" or "originally"
- Look for written rationale before inferring it: commit messages, PR references in the log, `CHANGELOG.md`, ADRs in `docs/`
- Treat code smells as present-tense facts only — "this has two implementations" is observable; "they're mid-migration from the old one" is a story until the log confirms it
- Never claim something "used to work" or "was changed" between sessions without diffing or checking the log
- If history is unknowable from the available record, say "I don't know why this is here" — that sentence keeps investigations alive instead of closing them on fiction

**Red flags that you're about to violate this:**
- "This was clearly refactored at some point..."
- "Someone must have added this to work around..."
- "This is the legacy version they migrated off of..."
- "This code looks recent compared to the rest..."
- "Judging by the style, an earlier developer..."
- Writing a past-tense sentence about the codebase with zero git commands run this session

---

## Why It Works

1. **It names the genre.** "Fabrication with a confident narrative voice" reframes historical inference from analysis (respectable) to storytelling (checkable), which makes the AI notice when it's doing it.

2. **It targets the explanatory kill-shot.** Invented history is harmful because it satisfies why-questions and stops the search. Stating that mechanism makes "I don't know why this is here" feel like the contribution it actually is.

3. **It maps each claim type to a command.** When/who/what-changed each have a one-line git answer (`log`, `blame`, `-S`). The lookup is cheaper than the narration, removing the efficiency excuse.

4. **It draws the present/past evidence line.** "Two implementations exist" vs. "a migration is underway" cleanly separates what code can prove from what only the log can — a distinction the AI otherwise blurs mid-sentence.

## Origin

An AI reviewing a payment module explained a strange double-write as "a remnant of the old database migration, safe to remove now." Compelling story; the user removed it. `git blame` would have shown the double-write was added eight days earlier — deliberately, with a commit message explaining it kept a reconciliation system alive during a vendor transition. Finance noticed the discrepancy at month-end close, and the "remnant" was restored with an apology and a comment block in all caps.
