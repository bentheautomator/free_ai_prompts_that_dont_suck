---
title: Read Internal Code Before Calling It
slug: read-internal-code-before-calling-it
category: context
tags: [universal, verification, assumptions]
works_with: all
severity: high
one_liner: "AI guessing signatures of the project's own functions instead of opening them"
---

# Read Internal Code Before Calling It

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from calling the project's own functions with guessed signatures, arguments, and return shapes.

**[Copy-paste ready version](../../install/read-internal-code-before-calling-it.md)** — just the instruction block, no explanation.

## The Problem

The AI needs to call `getUser()` from the project's own codebase. It hasn't opened the file, but the name is so familiar that a signature materializes on its own: takes an id, returns a user object — probably with `id`, `name`, `email`. So it writes `const { email } = await getUser(userId)`. The real function takes an options object, returns `{ data, error }`, and isn't async. Three guesses, three misses, all on code that was sitting on disk the whole time.

Public libraries at least give the AI training data to draw on. Internal code gives it nothing — every signature is a pure invention shaped by what similar functions look like elsewhere. Whether you get a loud failure depends on luck: TypeScript might catch the mismatch, but a dynamically-typed codebase, an `any`-typed boundary, or a structurally-compatible-but-wrong call sails through to runtime. Destructuring `undefined`, awaiting a non-promise, passing positional args to an options-object function — these are the fingerprints of a guessed signature.

The defining feature of this failure is that the ground truth is always available. It's the project's own code. There is no signature in the repo that costs more than one file-read to know exactly.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Read Internal Code Before Calling It

NEVER call, import, or extend a function, class, or module from this project without reading its actual definition first. Internal code has no documentation in your training data — any signature you produce without reading is invented, not remembered.

A guessed call can be structurally plausible and completely wrong: wrong argument shape, wrong return type, wrong sync/async behavior, wrong error contract.

**Before writing a call to project-internal code:**
- Open the definition and read the real signature: parameter names, types, defaults, and whether it's async
- Read the return shape from the code itself — does it return the value, a `{ data, error }` pair, a promise, null on miss, or throw?
- Check how existing callers use it (grep for the function name) — call sites encode contracts the signature alone doesn't show, like required setup or expected ordering
- Note the error behavior: functions that throw and functions that return error values need different call sites
- For classes, check the constructor and required initialization before instantiating; for modules, check what's actually exported rather than assuming a default export

**Red flags that you're about to violate this:**
- "A function with this name would take..."
- "It probably returns the user object directly..."
- "Internal helpers like this are usually async..."
- "I'll destructure the obvious fields from the result..."
- "The signature is predictable from how it's used over here..." — when you haven't read even that usage
- Writing arguments to a project function whose definition you have not had open this session

---

## Why It Works

1. **It severs the false analogy to library knowledge.** The AI treats internal functions like public APIs it half-remembers, but there is nothing to remember — stating that every unread signature is *invented* removes the comfortable middle ground.

2. **It enumerates the four guessable dimensions.** Arguments, return shape, asyncness, error contract — making each one an explicit checkbox prevents reading just enough to guess the rest.

3. **It adds call sites as a second source.** Signatures don't show usage contracts; one grep for existing callers catches required-setup and ordering constraints that even a careful read of the definition misses.

4. **It defines "verified" mechanically.** "Definition open this session" is a check the AI can self-apply mid-generation, unlike the fuzzy standard of "being reasonably confident."

## Origin

Asked to add a notification on order completion, the AI called the project's internal `sendNotification(userId, message)` — a signature it invented. The real function took a single event object and returned a queued-job handle; passed two strings, it queued a malformed job that the worker silently dropped. Code review approved it because the call read naturally. Three weeks of missing order notifications later, the root cause turned out to be two arguments that had never matched any signature in the repo.
