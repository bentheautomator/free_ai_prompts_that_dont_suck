---
title: Mandated Tools Override Habits
slug: mandated-tools-override-habits
category: instruction-following
tags: [universal, rules, tooling]
works_with: all
severity: medium
one_liner: "Rules file says pnpm, AI keeps typing npm out of habit"
---

# Mandated Tools Override Habits

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from reverting to its default tools when the project has mandated specific ones.

**[Copy-paste ready version](../../install/mandated-tools-override-habits.md)** — just the instruction block, no explanation.

## The Problem

The rules file says `pnpm`, and the AI runs `npm install` anyway — not in defiance, but on autopilot. The project mandates `rg` over `grep`, the project's `make test` wrapper over raw `pytest`, the in-repo codegen script over hand-writing boilerplate. The AI knows all of this when asked. At the moment of typing a command, though, muscle memory wins: the training-default tool comes out because it's the highest-probability next token, and the mandate never got a vote.

Tool mandates are uniquely vulnerable because commands are emitted dozens of times per session, each one a fresh chance for the default to resurface — and because the wrong tool often *works*, sort of. `npm install` in a pnpm repo doesn't error; it generates a competing lockfile and a subtly different `node_modules`. Raw `pytest` runs, just without the env setup the wrapper provides, producing failures that send everyone debugging the wrong layer. The damage is rarely dramatic. It's a slow contamination: wrong lockfiles committed, caches in the wrong format, results from environments the project doesn't actually use.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Mandated Tools Override Habits

When the project mandates a tool, ALWAYS use that tool — for every invocation, all session. Your default tooling is overridden, not merely augmented.

**The core problem:** Commands come out on autopilot. The training-default tool (`npm`, `grep`, raw test runners) is your highest-probability output, so it resurfaces at every command unless the mandate actively wins each time — and the wrong tool often half-works, contaminating the project quietly instead of erroring loudly.

**Do this:**

- On entering a project, note its tool mandates (package manager, test command, search tool, formatters, wrapper scripts) and treat them as substitutions: every time you would reach for the default, emit the mandated tool instead
- Use the project's wrapper commands (`make test`, `scripts/build.sh`) rather than the underlying tools they wrap — the wrapper exists because the raw invocation is wrong here
- If a mandated tool appears broken or unavailable, STOP and report it; do not silently fall back to the default
- Before running any package, build, or test command, double-check the tool choice — these are the highest-habit, highest-contamination commands

**Do not:**

- Mix tools ("I'll use pnpm for installs but npm for scripts")
- Use the default "just for a quick check" — quick checks with the wrong tool produce wrong answers and wrong artifacts (lockfiles, caches)
- Assume tool equivalence; the project chose deliberately, and the differences are usually the point

**Red flags that you're about to violate this:**

- (typing the default command without having considered the mandate at all)
- "These tools are interchangeable for this purpose"
- "The wrapper script is just calling X anyway, so I'll call X directly"
- "It's a one-off command; the tooling rule is about regular workflow"
- "The mandated tool errored, so I'll quietly use the standard one"

---

## Why It Works

1. **It frames mandates as substitutions, not additions.** The default isn't competing with nothing — it's the strongest habit in the model. Defining the mandate as "every time you'd reach for X, emit Y" attaches the rule to the exact moment the habit fires.

2. **It explains why wrappers exist.** "The wrapper just calls X anyway" is the most common bypass logic. Stating that the wrapper exists *because* the raw invocation is wrong here pre-empts the unwrapping move.

3. **It blocks the silent fallback.** When the mandated tool breaks, the AI's helpful instinct is to substitute quietly — which converts a visible tooling problem into invisible contamination. Stop-and-report keeps the failure loud and the environment clean.

4. **It concentrates checking on the high-risk commands.** Package, build, and test invocations are both the most habitual and the most artifact-producing. A targeted double-check there costs little and covers most of the damage surface.

## Origin

A repo's rules file specified pnpm with a frozen lockfile policy. The assistant, partway through a dependency upgrade, ran `npm install` twice out of habit — generating a `package-lock.json` alongside `pnpm-lock.yaml` and resolving two transitive dependencies differently. CI used pnpm and stayed green; one developer's local environment picked up the npm lockfile and spent a day chasing a "works in CI, fails locally" bug down to a version skew neither lockfile alone would have caused. The rules file's first line named the package manager. Habit had simply outvoted it, twice.
