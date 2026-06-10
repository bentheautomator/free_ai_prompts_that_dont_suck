---
title: Construct Dependencies at the Composition Root
slug: construct-dependencies-at-the-composition-root
category: architecture
tags: [universal, architecture, coupling]
works_with: all
severity: medium
one_liner: "Services newing up their own DB clients five layers below main()"
---

# Construct Dependencies at the Composition Root

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from constructing clients, services, and connections deep inside business logic instead of receiving them from the place where the application is assembled.

**[Copy-paste ready version](../../install/construct-dependencies-at-the-composition-root.md)** — just the instruction block, no explanation.

## The Problem

A function deep in the codebase needs an HTTP client, so the AI writes `client = httpx.Client()` right there in the function body. A service needs the repository, so its constructor builds one: `self.repo = OrderRepository(Database(os.environ["DB_URL"]))`. Each construction is locally complete — no signature changes, no wiring, the code runs. And each one hardwires a concrete choice (which class, which config, which connection) into a layer whose job was the business logic, not the assembly.

Deep construction has a precise set of consequences. The dependency is unswappable for tests, so tests of the logic either hit the real network/database or resort to monkeypatching internals. Configuration reads scatter to wherever construction happens, so "what does this app need from the environment" has no single answer. Resources spawn redundantly — every call builds a fresh client instead of sharing a pool, which is how codebases end up with connection exhaustion under load. And changing how a thing is built (add a timeout, swap the implementation, pool the connections) means hunting down every buried construction site.

AI assistants construct in place because it's the only option that requires no knowledge of the rest of the program. Receiving a dependency means knowing who calls you and editing them; building it means knowing only the class name. Locally, building always wins. Architecturally, it loses every time.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Construct Dependencies at the Composition Root

NEVER construct stateful or configurable dependencies — database connections, HTTP clients, repositories, service objects, queue producers — inside business logic. Construction happens at the composition root (main, app startup, the DI container, the request factory); everything below receives its dependencies as constructor or function parameters.

Code that builds its own dependencies has decided, unilaterally and invisibly, which implementation, which config, and which lifecycle the whole application gets.

- A class that needs a repository takes it in its constructor; the place that builds the class supplies it. If that means a parameter ripples up a level or two, that ripple is the wiring becoming visible — it's the feature, not the cost
- Find the codebase's existing composition root before inventing one: a `main()`, an app factory, a DI container, framework startup hooks. Add new wiring there, in the established style
- Don't read config (env vars, settings) deep in the call stack to build things; config is read at the root, dependencies are built from it once, and objects receive them
- Value objects and pure data (a dataclass, a datetime, a Decimal) are constructed wherever needed — this rule is about dependencies with identity, state, configuration, or I/O
- Don't overcorrect into a framework: passing parameters IS dependency injection; introducing a DI container the codebase doesn't have is a rival-pattern violation, not compliance
- If you're three layers deep and the dependency isn't available, the fix is adding it to the constructor chain — not `new`, not a global, not a `get_client()` that hides the `new`

**Red flags that you're about to violate this:**
- "I'll just create the client here, it's only used in this function..."
- "Threading it through two constructors is too much plumbing..."
- "Reading the env var here is simpler than passing config down..."
- "A fresh connection per call is fine, it's not hot code..."
- "I'll add a helper that constructs it on demand..."

---

## Why It Works

1. **It puts all assembly knowledge in one place.** When construction is centralized, "what does this app talk to, with what config" is answerable by reading one file — the question every incident responder asks first.

2. **It makes substitution structural, not magical.** Dependencies that arrive as parameters can be swapped for fakes by passing fakes; nothing to patch, no test framework spelunking required.

3. **It reframes the ripple as documentation.** The parameter that travels up two constructors is the dependency graph becoming visible in signatures; hiding the wiring doesn't remove it, it just removes the ability to read it.

4. **It bounds itself against both failure modes.** Carving out value objects stops pedantic over-application, and banning the spontaneous DI container stops the equally common overcorrection.

## Origin

A reporting endpoint built its own database connection inside the query function — reasonable when written, since the function predated the app's pooling. Under a traffic spike, each request opened a fresh connection, exhausted the database's connection limit, and took down not just reporting but every service sharing that database. The incident review found nine other buried construction sites doing the same thing at lower volume, each invisible because no signature anywhere mentioned them. Moving construction to the app factory was a day's work; finding all nine sites was the week.
