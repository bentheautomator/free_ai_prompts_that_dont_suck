---
title: Banned Stays Banned
slug: banned-stays-banned
category: instruction-following
tags: [universal, rules, constraints]
works_with: all
severity: high
one_liner: "Banned libraries and patterns creeping back in through new code"
---

# Banned Stays Banned

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents explicitly banned libraries, patterns, and approaches from being reintroduced whenever the ban isn't front of mind.

**[Copy-paste ready version](../../install/banned-stays-banned.md)** — just the instruction block, no explanation.

## The Problem

Negative constraints have a special failure profile. "Use library X" gets followed because doing the task reminds you of it. "Never use library Y" generates no reminders at all — there's no moment in the workflow where the ban naturally surfaces. So the AI, six files into a refactor, reaches for `moment` in a repo that banned it for `date-fns` months ago, or reintroduces the singleton pattern the team spent a quarter removing, or imports from the deprecated internal package the rules file lists under "never."

Bans are usually written in blood: a bundle-size incident, a security advisory, a pattern that caused a class of bugs. But the AI's training makes the banned thing the *most natural* thing to produce — that's typically why it needed banning. Every moment of inattention defaults toward the violation. And reintroductions are expensive out of proportion to their size: one new import of a banned library re-establishes the dependency the team had migrated away from, and every subsequent grep for "did we remove it everywhere?" comes back dirty again.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Banned Stays Banned

NEVER introduce a library, pattern, API, or approach the project has banned — in any file, for any reason, no matter how natural it feels. Bans don't expire and don't have small violations.

**The core problem:** Banned things are usually banned because they're the natural default — which means every lapse of attention drifts toward the violation. And bans generate no workflow reminders: nothing about writing date code reminds you that `moment` is forbidden here.

**Do this:**

- Maintain an explicit list of this project's bans (from the rules file, deprecation notices, and user statements) and check new imports, dependencies, and patterns against it before writing them
- When you're about to use something from your defaults — a library, an idiom, a design pattern — pause on the ones that feel most automatic; automatic is where bans get broken
- Use the project's designated replacement; if no replacement is named and the ban blocks you, ask — don't decide the ban must not have meant this case
- Honor bans in EVERY context: tests, scripts, prototypes, and generated code reintroduce dependencies just as effectively as production code

**Do not:**

- Reintroduce a banned thing because existing old code still uses it ("there's precedent in the codebase")
- Treat a ban as covering only the exact version, import path, or syntax it named — equivalents are included
- Assume a ban lapsed because time passed or because following it is inconvenient today

**Red flags that you're about to violate this:**

- "This library is the standard way to do this"
- "It's already used elsewhere in the repo, so one more won't matter"
- "The ban was probably about production code, and this is a script"
- "I'll use it just for this small case; it's the perfect fit"
- "I don't recall anything prohibiting this" (without checking)

---

## Why It Works

1. **It explains why bans break differently.** The banned thing is the model's strongest prior — the ban must beat the default on every single generation. Naming that asymmetry tells the AI *where* to spend vigilance: on the choices that feel most automatic.

2. **It creates the missing reminder.** Bans fail for lack of workflow surface area. An explicit ban list checked at import/dependency/pattern time manufactures the checkpoint the workflow doesn't naturally provide.

3. **It kills the precedent loophole.** Legacy usage of the banned thing is the most persuasive false permission ("it's already here"). Explicitly ruling it out blocks the one argument that feels like evidence.

4. **It extends bans to equivalents and all contexts.** Version-renamed imports and "it's just a test" are the two standard reentry paths; closing both leaves no door that doesn't go through the user.

## Origin

A team spent two sprints migrating off a deprecated internal HTTP client after a connection-leak incident, and their rules file said plainly: never import it again. Three weeks later, their assistant scaffolded a new integration test that imported the old client — it was, after all, all over the team's older code, which made it look like the house style. The test suite started leaking connections in CI, intermittently failing unrelated builds for days before anyone thought to grep for the import they "knew" was gone. The migration was re-verified file by file. Again.
