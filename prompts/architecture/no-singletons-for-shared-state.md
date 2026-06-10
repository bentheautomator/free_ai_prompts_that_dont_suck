---
title: No Singletons for Shared State
slug: no-singletons-for-shared-state
category: architecture
tags: [universal, architecture, state]
works_with: all
severity: high
one_liner: "getInstance() globals smuggling shared state past every signature"
---

# No Singletons for Shared State

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from solving "two places need the same object" with a module-level instance or getInstance(), creating hidden global state every function can secretly touch.

**[Copy-paste ready version](../../install/no-singletons-for-shared-state.md)** — just the instruction block, no explanation.

## The Problem

Two distant parts of the code need the same database pool, cache client, or settings object. Threading it through the intervening call stack means changing signatures, and changing signatures means touching files outside the immediate task. So the AI takes the universal shortcut: a module-level `db = Database()`, a `Cache.getInstance()`, a global `current_session`. Problem solved in one line, and every function in the codebase just gained an invisible parameter.

Hidden state is the gift that keeps on taking. Tests now interfere with each other through the shared instance, so they pass alone and fail in suites — or worse, pass in suites and fail alone. Construction happens at import time, so importing a module for one pure function connects to the database. Two configurations can't coexist in one process, which surfaces years later as "we can't run a second tenant/worker/test server." And because no signature mentions the dependency, finding what actually uses the singleton means grepping the world.

AI assistants reach for singletons because the alternative — passing the dependency explicitly — has a visible cost (more parameters, more edited files) while the singleton's cost is deferred and diffuse. The shortcut compiles today; the bill arrives in every test and every future change.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No Singletons for Shared State

NEVER create a singleton, module-level instance, or `getInstance()` accessor to share a stateful object (database pools, caches, clients, sessions, registries). Shared dependencies are passed explicitly — as parameters, constructor arguments, or app context — so every function's signature tells the truth about what it uses.

A singleton is a global with a design-pattern alibi: it hides a dependency from every signature, couples tests through shared state, and hardwires "exactly one of these per process" into the architecture.

- If two components need the same object, construct it once where the app starts and pass it to both; "where the app starts" is the one place allowed to know how everything is built
- Don't initialize stateful objects at module import time; importing should never connect, open, or allocate
- A `get_db()` accessor reading a module global is the same singleton with extra steps; so is a class with all-static methods holding state
- Stateless constants and pure functions at module level are fine — this rule is about state and connections, not about banning module-level code
- If the codebase already has an established singleton (e.g., a framework-managed app object), use it rather than adding a parallel one — but do not mint new ones

**Red flags that you're about to violate this:**
- "Passing this through four layers means touching four files..."
- "Everything needs the config, so it should just be globally available..."
- "It's not a global, it's the singleton pattern..."
- "There will only ever be one of these anyway..."
- "I'll add a getInstance() so callers don't need it injected..."
- "The tests can just reset it in teardown..."

---

## Why It Works

1. **It keeps signatures honest.** When dependencies are parameters, "what does this function touch" is answerable by reading one line; that legibility is what the singleton silently spends.

2. **It localizes construction knowledge.** Allowing the composition point to wire everything gives the AI a sanctioned answer to "but then who creates it?", which is the question that usually triggers the global.

3. **It names the disguises.** `get_db()`, static-method holders, and import-time construction are the forms AIs actually emit; rules that only say "no singletons" miss all three.

4. **It predicts the multiplicity bug.** "Only one of these will ever exist" fails on the first parallel test run, second tenant, or per-request configuration — making that failure explicit beats discovering it in production.

## Origin

A job-processing service kept its queue client in a module-level singleton, constructed at import. The test suite developed a notorious property: full runs passed, but any test file run alone failed, because a conftest import elsewhere had been initializing the client as a side effect. Engineers spent months adding reset fixtures instead of fixing the root cause. The forcing event was scaling to per-region queues — "exactly one client per process" was load-bearing in 60 files, and the migration to explicit injection took two engineers most of a sprint.
