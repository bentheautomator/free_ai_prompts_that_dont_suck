---
title: Assume Your Code Is the Bug, Not the Library
slug: assume-your-code-is-the-bug-not-the-library
category: debugging
tags: [universal, debugging]
works_with: all
severity: high
one_liner: "AI blaming the framework, library, or compiler instead of its own code"
---

# Assume Your Code Is the Bug, Not the Library

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from diagnosing battle-tested libraries, frameworks, and compilers as broken before suspecting the code that was written yesterday.

**[Copy-paste ready version](../../install/assume-your-code-is-the-bug-not-the-library.md)** — just the instruction block, no explanation.

## The Problem

"This looks like a bug in the ORM's handling of nested transactions." It almost never is. The ORM has millions of users exercising nested transactions daily; the application code calling it was written last Tuesday and has one user. Yet AI assistants reach for the library-bug diagnosis with remarkable ease — proposing version downgrades, monkey-patches, and "workarounds for the framework issue" — because it's the one theory that requires no further self-examination. If the library is broken, the investigation is over and nobody's code (especially not the code the AI just wrote) is at fault.

The base rates here are brutal. Mature dependencies fail at a rate orders of magnitude below application code, and apparent library bugs are overwhelmingly misuse: a misunderstood API contract, a missing await, a config default that means something different than assumed, a lifecycle method called at the wrong time. The library-bug hypothesis also tends to arrive suspiciously early — often before the AI has read the relevant documentation section, and almost always before it has built a minimal case demonstrating the library misbehaving in isolation.

The cost compounds: downgrades that reintroduce patched vulnerabilities, monkey-patches that break on the next upgrade, and the real bug — sitting in application code — untouched behind a closed investigation.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Assume Your Code Is the Bug, Not the Library

NEVER conclude that a mature library, framework, compiler, or runtime is the bug until you have exhausted the far more likely explanation: the application code is using it wrong.

Your code is days old with one user; the dependency is years old with millions. The prior is not subtle, and "the framework is broken" is the one theory that conveniently ends all self-examination.

- Before suspecting the dependency, verify your usage against its actual documentation for this version — contracts, required call order, config semantics, threading/async rules; most "library bugs" are contract violations
- Check the version actually installed vs the docs you're reading, and check the changelog: behavior that "changed mysteriously" usually changed in a release note
- To accuse the library, build the evidence: a minimal standalone case that misbehaves with correct, documented usage and no application code involved; until that exists, the diagnosis stays "probable misuse"
- Search the library's issue tracker for the exact symptom — a known issue with a linked workaround is acceptable evidence; a hunch is not
- Do not downgrade versions, monkey-patch internals, or add "framework workaround" code as a first response — each of these encodes the unproven accusation into the codebase
- If the minimal case does prove a real dependency bug, say so with the evidence, and prefer the documented workaround or an upstream report over patching internals

**Red flags that you're about to violate this:**
- "This seems to be a bug in the library's handling of..."
- "The framework isn't respecting the config here, I'll work around it..."
- "Downgrading to the previous major version should resolve this..."
- "The compiler is optimizing this incorrectly..." (it isn't)
- Accusing a dependency before reading its docs for the feature in question
- A "workaround" arriving faster than a minimal reproduction would have

---

## Why It Works

1. **It states the base rate as a prior.** "Days old, one user vs years old, millions" gives the AI an explicit probability ordering that counters the convenience of the library-bug story.

2. **It names the motive.** The framework-is-broken theory is attractive because it ends self-examination; saying that out loud makes the AI recognize the theory as suspiciously self-serving when it arises.

3. **It sets an evidence bar for the accusation.** Requiring a minimal standalone misbehavior case doesn't forbid the (real, occasional) library bug — it makes claiming one cost something, which filters out the lazy version.

4. **It blocks the damage vectors specifically.** Downgrades, monkey-patches, and workaround layers are how the unproven theory becomes permanent code; listing them as banned first responses contains the blast radius while the question is still open.

## Origin

An assistant diagnosed missing rows in a report as "a known issue with the database driver's cursor pagination" and implemented a manual pagination layer to work around it — 150 lines, with its own off-by-one. The driver was fine. The application code was mutating the result list while iterating it, a bug visible in the function directly above the call site. The workaround shipped, doubled query load, and was finally deleted months later when someone tried to reproduce the "driver issue" in isolation and couldn't.
