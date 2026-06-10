---
title: Read the Repo Docs Before Guessing
slug: read-the-repo-docs-before-guessing
category: context
tags: [universal, grounding, conventions]
works_with: all
severity: high
one_liner: "AI guessing answers that README, CONTRIBUTING, or docs/ already state outright"
---

# Read the Repo Docs Before Guessing

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from inventing answers to questions the repository's own documentation already answers.

**[Copy-paste ready version](../../install/read-the-repo-docs-before-guessing.md)** — just the instruction block, no explanation.

## The Problem

Repos carry their own manuals. README explains setup, CONTRIBUTING explains the workflow, `docs/` holds architecture notes and ADRs, and half the directories have a local README explaining what lives there. AI assistants reliably skip all of it. Asked how to run the project, the AI guesses `npm start`. Asked why the service is split this way, it theorizes. Asked about deployment, it describes generic CI — while `docs/deploying.md` sits unread with the real answer, including the two warnings that exist because someone got burned.

The pattern-matching reflex is the culprit: documentation is for filling knowledge gaps, and the AI doesn't experience a gap. It has seen ten thousand similar projects; an answer is always available, instantly, from the prior. Reading docs feels like a detour to confirm what it already "knows." But repo docs encode exactly the deltas from the generic case — special setup steps, non-obvious constraints, decisions with reasons — which means the AI's prior is wrong precisely where the docs are most valuable.

There's a second cost: when the AI guesses instead of reading, the team's investment in writing docs is silently voided. Docs nobody consults rot, and the loop that keeps them alive breaks.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Read the Repo Docs Before Guessing

ALWAYS check whether the repository's own documentation answers a question before answering it from general knowledge. Repo docs exist specifically to record where this project differs from the generic case — which is exactly where your prior is wrong.

Guessing past existing docs gives the user a generic answer to a question their team already answered precisely.

**Before answering process, setup, or architecture questions:**
- Check the canonical locations: `README.md` (root and per-directory), `CONTRIBUTING.md`, `docs/`, `ADR`/`adr`/`rfcs` directories, wiki exports, `*.md` next to the code in question
- For "how do I run/build/test/deploy this" — the README and CONTRIBUTING answer before you do; quote their commands rather than inventing conventional ones
- For "why is this designed this way" — search docs and ADRs for the decision before theorizing; a recorded rationale beats a plausible one every time
- Search cheaply: a filename glob for `*.md` plus a grep for the topic keyword takes seconds and either finds the answer or proves it's not written down
- When docs and code disagree, report the conflict instead of silently picking one — stale docs are a finding, not an inconvenience
- Cite the doc you used ("per CONTRIBUTING.md, PRs need...") so the user knows the answer is theirs, not generic

**Red flags that you're about to violate this:**
- "Standard setup for this kind of project is..."
- "I can answer this without checking their docs..."
- "The README is probably just boilerplate..."
- "The design rationale is most likely the usual one..."
- "Nobody keeps docs up to date anyway..."
- Answering a how-does-this-team-do-it question with zero `.md` files read this session

---

## Why It Works

1. **It locates the prior's blind spot.** "Docs record the deltas from generic; your prior is generic" explains why confident knowledge and documentation aren't redundant — they cover complementary territory, and the docs cover the part that matters.

2. **It makes the check falsifiable and cheap.** Glob plus grep either surfaces the doc or proves none exists. Both outcomes are useful, so there's no scenario where checking was wasted.

3. **It handles stale docs without licensing skips.** "Docs rot" is the AI's favorite excuse to not look; converting doc/code conflicts into reportable findings keeps the check valuable even when the docs lose.

4. **It attributes answers to their source.** Citing the doc distinguishes "your team's documented process" from "common practice" — a distinction the user needs and fluent prose otherwise erases.

## Origin

A contractor's AI was asked to get a legacy service running locally. It guessed the conventional incantation — install, migrate, start — and spent ninety minutes debugging the cascade of failures that followed. `docs/local-setup.md`, eleven lines long, listed the required steps including a seed script and a local TLS certificate, and ended with a warning about exactly the migration error the AI had been fighting. The file's last commit message was "PLEASE read this before setup." It had been written after the previous contractor did the same thing.
