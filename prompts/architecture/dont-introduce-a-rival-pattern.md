---
title: Don't Introduce a Rival Pattern
slug: dont-introduce-a-rival-pattern
category: architecture
tags: [universal, architecture, consistency]
works_with: all
severity: medium
one_liner: "A second way of doing things landing next to the codebase's existing way"
---

# Don't Introduce a Rival Pattern

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from solving a problem with a new pattern when the codebase already has an established one for exactly that problem.

**[Copy-paste ready version](../../install/dont-introduce-a-rival-pattern.md)** — just the instruction block, no explanation.

## The Problem

The codebase fetches data with custom hooks. The AI, asked to add a feature, fetches data with a context provider plus a reducer — because that's a perfectly good pattern and it's the one the AI reached for first. The codebase does error handling with result types; the new code throws. The codebase injects dependencies through constructors; the new service grabs them from a container. Each choice is defensible in a vacuum. None of them is the codebase's choice.

The result is a codebase that is the union of every contributor's habits. Readers now need to know both patterns to read one feature. Reviewers can't tell deliberate change from accident. The next AI session sees two patterns and picks one at random, amplifying whichever side it lands on. Eventually someone proposes "standardizing," which is a quarter of migration work to get back to where the codebase started.

AI assistants do this by default because they generate the statistically common solution, not the locally established one. Nothing about the prompt says "we do data fetching with hooks here" — that fact lives in the twenty existing files the AI didn't read before writing the twenty-first.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Don't Introduce a Rival Pattern

NEVER introduce a new pattern for a problem the codebase already solves an established way. Before writing the structural parts of a change — data fetching, error handling, dependency wiring, validation, state management — find two or three existing examples and match them.

A second pattern doesn't replace the first one; it coexists with it forever, and every reader pays for both.

- Before structuring new code, open the most recently touched files that do the same kind of thing; their shape is the spec
- Match the codebase even where your preferred pattern is genuinely better — consistency beats local optimality, because the next maintainer extrapolates from what exists
- This covers mechanisms, not just style: don't add a DI container to a constructor-injection codebase, an event emitter to a direct-call codebase, exceptions to a result-type codebase, or a new folder convention to an established layout
- If the existing pattern truly cannot express what the task needs, say so explicitly and propose the new pattern as a decision for a human — don't smuggle it in inside a feature diff
- If the codebase has two competing patterns already, match the one in the area you're touching, or the more recent one; don't add a third

**Red flags that you're about to violate this:**
- "The way I know is cleaner than what they're doing..."
- "This is the standard/modern approach, they'll want it eventually..."
- "It's a new file, so existing conventions don't constrain it..."
- "I'll do it the better way here and it can be the new direction..."
- "The pattern difference is small, nobody will notice..."

---

## Why It Works

1. **It makes the codebase the spec.** "Open three examples first" replaces the AI's training-data prior with the project's actual prior, which is the only one that matters for consistency.

2. **It separates proposing from smuggling.** New patterns are sometimes right — but as a flagged decision a human can accept, not a fait accompli buried in a feature branch.

3. **It blocks the extrapolation cascade.** Every pattern present in the codebase becomes a precedent the next contributor (human or AI) may copy; refusing the second instance is how you avoid migrating the twentieth.

4. **It removes "better" as a unilateral trump card.** Local optimality arguments are usually true and don't matter; the rule states the priority order explicitly so the AI doesn't have to relitigate it per file.

## Origin

A frontend team found, during an audit, four distinct data-fetching approaches in one app: the original hooks, plus three others, each introduced by a different AI-assisted feature over eight months. None was wrong. Together they meant every loading-state bug had four possible shapes, and onboarding docs had a section titled "which fetching pattern am I looking at?" The unification project took six weeks and changed no behavior at all.
