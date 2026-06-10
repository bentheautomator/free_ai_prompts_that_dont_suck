---
title: Match Codebase Naming Conventions
slug: match-codebase-naming-conventions
category: code-quality
tags: [universal, naming]
works_with: all
severity: medium
one_liner: "AI naming new code by its own taste instead of the codebase's conventions"
---

# Match Codebase Naming Conventions

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from introducing names that clash with the vocabulary and casing the codebase already uses.

**[Copy-paste ready version](../../install/match-codebase-naming-conventions.md)** — just the instruction block, no explanation.

## The Problem

A codebase where every data-loading function starts with `fetch` gains, courtesy of an AI session, a `getUserProfile`, a `loadSettings`, and a `retrieveOrders` — three new verbs for the one concept the team had standardized. Files named `user-service.ts` get a sibling named `PaymentService.ts`. A Python project using `snake_case` acquires a `getCacheKey` because the AI was thinking in JavaScript that day.

Naming conventions are how developers predict code they haven't read. When every fetcher starts with `fetch`, you can type `fetch` and let autocomplete show you the API surface. When test files are all `*_test.py`, the runner finds them. The AI breaks these contracts not out of disagreement but out of indifference: it names things by the conventions of its training-data average, which is nobody's codebase in particular. Each individually reasonable name erodes the predictability — until searching for "the function that gets a user" requires guessing four verbs, and a test silently doesn't run because its filename matched no glob.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Match Codebase Naming Conventions

ALWAYS derive names from the codebase's existing conventions, never from your own defaults. Before naming anything — function, variable, file, class, CSS class, database column, event — find three existing examples of the same kind of thing and follow their pattern.

Conventions are a prediction contract: they let people find code by guessing its name and let tools find files by glob. A name in your style instead of theirs breaks the contract one identifier at a time.

**Conventions to detect and match:**
- Verb vocabulary: if the codebase says `fetch`, don't introduce `get`/`load`/`retrieve` for the same concept; if it says `handle`, don't add `on`/`process` variants
- Casing per context: function/variable casing, class casing, constant casing, file naming (`kebab-case.ts` vs `PascalCase.tsx` vs `snake_case.py`) — these often differ by directory; match the local norm
- Affix patterns: `use*` for hooks, `*Service`/`*Repo` suffixes, `is*`/`has*` for booleans, `_test`/`.spec` for tests, `I*`/`*Impl` if (and only if) they're already in use
- Domain vocabulary: if the codebase calls them `accounts`, your new code doesn't call them `users` — synonyms fork the domain language
- Functionally significant names (test file patterns, migration prefixes, route file conventions) are hard requirements: a wrong name there means tools silently skip your file

**Red flags that you're about to violate this:**
- "I'll name this what it would conventionally be called..." (whose convention?)
- "getUser is the standard name for this..."
- "The casing difference is cosmetic..."
- "I'll use the clearer synonym instead of their term..."
- "New file, so I can use better naming here..."
- Naming something without having looked at what its three nearest siblings are named

---

## Why It Works

1. **It replaces an unanswerable question with a procedure.** "What's the right name" invites the model's training-data average. "What are three siblings named" has a checkable answer in this repo.

2. **It elevates names from aesthetics to contract.** The AI deprioritizes naming because it seems cosmetic. Tying names to search predictability and tool globs gives the rule consequences the model will respect.

3. **It defends the domain vocabulary specifically.** Synonym drift (`users` vs `accounts`) is the most damaging variant because it forks how the team talks about the system, and it's invisible to linters. Naming it makes it visible to the AI.

4. **It flags the load-bearing names.** Test patterns and migration prefixes are conventions with teeth — violations don't look ugly, they silently don't run. Separating those from style conventions calibrates the AI's caution correctly.

## Origin

An AI added a test file named `validation.test.py` to a Python project whose pytest config collected `test_*.py` and `*_test.py`. The suite passed in CI — by never running the new tests at all. The bug those tests would have caught shipped two sprints later, and the file was discovered during the postmortem, sitting in the repo, green-checkmarked, never once executed.
