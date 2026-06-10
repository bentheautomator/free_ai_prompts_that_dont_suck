---
title: No New Dependencies Uninvited
slug: no-new-dependencies-uninvited
category: scope
tags: [universal, scope]
works_with: all
severity: high
one_liner: "AI installing new packages to solve problems a few lines would fix"
---

# No New Dependencies Uninvited

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from adding new packages to the project without asking, especially for problems a few lines of code would solve.

**[Copy-paste ready version](../../install/no-new-dependencies-uninvited.md)** — just the instruction block, no explanation.

## The Problem

The task needed a debounce. The diff adds `lodash`. The task needed to left-pad an ID; the diff adds a string utility package. The task needed one HTTP call in a project that already uses the platform's fetch; the diff installs a request library, because that's the idiom the AI has seen most. One small function was needed; an entire dependency arrived, uninvited, with its transitive tree behind it.

A new dependency is one of the highest-commitment changes a codebase can absorb, and the AI makes it casually. Each package is code your team now ships but didn't review, a supply-chain trust decision, a license to vet, a name that future security advisories will page someone about, and weight in every install and build forever. Many organizations gate new dependencies behind explicit review precisely because the cost is so asymmetric to the moment of `install`. An AI that adds packages mid-task walks straight past that gate — and often past an existing in-project utility, or an already-installed package, that did the same job.

The few-lines-or-fewer cases are the worst trade: a 12-line debounce you own versus a package you don't. But even the bigger cases are not the AI's call to make alone. "This needs a real library — may I add X?" is one sentence.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No New Dependencies Uninvited

NEVER add a new package, library, or external tool to the project without asking first. Solve small problems with small code; raise big ones as a question.

The core problem: a dependency is a permanent trust, security, license, and maintenance commitment made on the whole team's behalf, and it should never enter the project as a side effect of a task.

- Before reaching for a package, check in order: can a few lines of code do this; does the project already contain a utility for it; is a package already installed that covers it
- Functionality worth roughly a dozen lines or less (debounce, deep-get, padding, simple parsing, basic retries-if-requested) gets written inline, not installed
- Never add a package because it's the idiom you know best when the project's existing stack covers the need (e.g., adding a request library to a project using fetch)
- When a dependency genuinely is the right answer (crypto, timezone math, parsing complex formats — things teams should not hand-roll), stop and ask: name the package, why hand-rolling is wrong here, and what it pulls in
- Never swap one installed dependency for an equivalent you prefer as part of another task
- Dev dependencies, build plugins, and tools count; "it's only a devDependency" is still a supply-chain decision

**Red flags that you're about to violate this:**
- "There's a great library for this, I'll add it..."
- "Everyone uses this package, it's basically standard..."
- "No point reinventing the wheel for a debounce..."
- "I'll install it now and they can remove it if they object..."
- "It's just a dev dependency, doesn't ship to production..."
- "The package does it more correctly than my code would..."

---

## Why It Works

1. **It orders the search correctly.** The AI's first instinct is the package it has seen most; the mandated sequence (few lines, in-project utility, installed package, then ask) puts cheaper options in front of that instinct.

2. **It sizes the hand-roll boundary.** "Roughly a dozen lines" makes the never-install zone concrete, while explicitly exempting crypto and timezone math heads off the opposite failure of hand-rolling the genuinely hard stuff.

3. **It frames installation as acting for the team.** The AI models `install` as a local convenience; naming the trust, license, and advisory commitments shows whose name the decision is signed in.

4. **It strips the install-now-remove-later excuse.** Lockfiles, imports, and habits make removal expensive; banning the "they can object later" path keeps the decision in front of the gate instead of behind it.

## Origin

For a date-difference calculation, an assistant added a convenience package with a deep transitive tree to a deliberately lean service. The addition sailed through review inside a feature PR. Eleven months later a security advisory landed on one of the transitive packages, paging the on-call, triggering the org's incident process, and forcing an emergency audit of where the dependency came from and what else it touched. The date math it provided was four lines of standard library.
