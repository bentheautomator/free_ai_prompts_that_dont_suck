---
title: No New Package for Stdlib Tasks
slug: no-new-package-for-stdlib-tasks
category: dependencies
tags: [universal, dependencies]
works_with: all
severity: medium
one_liner: "Stops adding lodash-class packages for things the stdlib already does"
---

# No New Package for Stdlib Tasks

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the assistant from installing a package for functionality the language's standard library already provides.

**[Copy-paste ready version](../../install/no-new-package-for-stdlib-tasks.md)** — just the instruction block, no explanation.

## The Problem

Ask an AI assistant to check whether an object is empty, and there's a decent chance it runs `npm install lodash` to call `_.isEmpty()` — three lines of vanilla JavaScript replaced by a dependency, its transitive tree, and a permanent entry in your supply-chain attack surface. The same instinct installs `axios` where `fetch` exists, `uuid` where `crypto.randomUUID()` exists, `rimraf` where `fs.rm` exists, and `requests` in a Python script that `urllib` would have handled fine.

The assistant does this because its training data is full of tutorials written when these packages were necessary, and because "install the famous package" pattern-matches as the safe, idiomatic answer. It optimizes for code that looks familiar, not for the long-term cost of the dependency. Nobody asked it to weigh that cost, so it doesn't.

The consequence shows up later: a `node_modules` directory that takes minutes to install, an audit report full of advisories in packages you use for one function, and the left-pad lesson relearned at your expense.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No New Package for Stdlib Tasks

NEVER add a dependency for functionality the standard library or built-in runtime APIs already provide. A dependency is a liability you adopt forever, not a feature you gain once.

Before any install command, ask: can the standard library do this in under ~20 lines? If yes, write those lines.

- Check the stdlib first: `fetch` instead of axios/node-fetch, `crypto.randomUUID()` instead of uuid, `structuredClone` instead of lodash.cloneDeep, `fs.rm` instead of rimraf, `Array.prototype.flat` instead of array-flatten, Python's `pathlib`/`json`/`urllib`/`dataclasses` instead of their package equivalents.
- If you only need one function from a utility library, write that function. `isEmpty`, `debounce`, `chunk`, and `pick` are each under ten lines.
- It is acceptable to add a dependency for genuinely hard problems: timezone math, parsers, cryptography you should not hand-roll, protocol implementations. The bar is "nontrivial to implement correctly," not "exists on npm."
- If the project already depends on a utility library, use it — do not write a parallel implementation. This rule governs adding NEW dependencies only.
- When you decide a new dependency is justified, say so explicitly and name what the stdlib lacks.

**Red flags that you're about to violate this:**
- "There's probably a package for this..."
- "Lodash is what most tutorials use here."
- "Installing it is faster than writing the helper."
- "It's a tiny package, it won't hurt."
- "axios has a nicer API than fetch."
- "Everyone depends on this anyway."

---

## Why It Works

1. **Reframes the trade:** "a dependency is a liability you adopt forever, not a feature you gain once" directly counters the assistant's default framing of an install as pure gain.
2. **Gives a concrete threshold:** "under ~20 lines of stdlib" converts a vague judgment call into a testable check the assistant can run before reaching for the install command.
3. **Names the rationalizations:** the red-flag phrases are the exact thoughts that precede the failure; surfacing them interrupts the pattern-match to tutorial code.
4. **Leaves a legitimate exit:** explicitly allowing hard-problem dependencies prevents the assistant from overcorrecting into hand-rolled crypto or date math.

## Origin

A team asked their assistant to add a single "is this config object empty" guard to a deploy script. The diff that came back added lodash to a service whose entire dependency tree had previously been four packages. The guard was one `Object.keys(cfg).length === 0` away; instead the service's install time doubled, and the package showed up in the next quarter's audit with a prototype-pollution advisory in a transitive dependency nobody could name.
