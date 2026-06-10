---
title: Check Consumers Before Updating Shared Libraries
slug: check-consumers-before-updating-shared-libraries
category: collaboration
tags: [universal, teamwork, shared-code]
works_with: all
severity: high
one_liner: "Stops upgrading a shared internal library without checking who consumes it"
---

# Check Consumers Before Updating Shared Libraries

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from updating a shared internal library — its dependencies, its build, its runtime requirements — without checking the projects that consume it.

**[Copy-paste ready version](../../install/check-consumers-before-updating-shared-libraries.md)** — just the instruction block, no explanation.

## The Problem

Internal shared libraries — the `common` package in the monorepo, the `@org/core` module four services import, the utilities wheel every Python project pins — sit upstream of consumers the AI never opens. Asked to add a feature to the library, the AI also bumps a transitive dependency to a new major version, raises the minimum runtime ("requires Node 22"), tightens a peer dependency range, or switches the build output format. The library's own tests pass. Then every consumer that pulls the new version inherits changes nobody evaluated against *their* dependency trees, runtime versions, and build setups.

The breakage is distributed and delayed, which makes it expensive. Service A's CI fails on an unresolvable peer dependency. Service B builds fine but crashes at startup on the runtime requirement. Service C, pinned loosely, picks up the change during an unrelated deploy and pages someone who has no idea the library changed. Each consuming team debugs in isolation, because from where they sit, the failure looks local.

The AI does this because the library is the repository it's working in, and the repository is, as far as it can perceive, the whole world. Consumers are listed nowhere in its context. A change that is green in the library looks finished — but for shared libraries, the library passing is the beginning of done, not the end.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Check Consumers Before Updating Shared Libraries

NEVER treat a shared internal library as a leaf project. Before changing its dependencies, runtime requirements, build output, or versioning, identify its consumers and evaluate the change from their side.

A library being green tells you almost nothing; libraries break people downstream, in projects you haven't opened.

- First, establish who consumes this package: search the monorepo for imports, check internal registry usage, look for a consumers list in docs. If you can't determine consumers, say so — that's a finding, not a license to proceed freely.
- Don't bump the library's dependencies (especially major versions or peer dependency ranges) as a side effect of feature work. Dependency changes ride into every consumer's tree; they deserve their own deliberate change.
- Don't raise minimum runtime/language versions, change build targets, or alter packaging (ESM/CJS, wheel tags, artifact layout) without flagging it as a consumer-impacting change.
- Version honestly: anything a consumer could observe — behavior, types, peer ranges, engines — that changes incompatibly is a major bump, not a patch.
- In monorepos, run the consumers' builds and tests, not just the library's, before calling the change done.
- Summarize consumer impact explicitly: who is affected, what they'll see, what they need to do.

**Red flags that you're about to violate this:**
- "The library's tests pass, so the change is safe."
- "I'll bump this dependency while I'm in here; staying current is good."
- "Requiring the newer runtime is fine; everyone should be on it anyway."
- "It's a patch release; consumers won't even notice."
- "Checking the consuming services is outside this repo's scope."

---

## Why It Works

1. **It inverts the frame of reference** — the AI evaluates changes from inside the library, and the rule forces evaluation from the consumer's dependency tree, where the breakage actually happens.
2. **It quarantines dependency and platform changes** from feature work, because riders in a library version are inherited by every consumer without review.
3. **It ties version numbers to observable change**, making the library's semver a real signal consumers can act on instead of a vibe.
4. **It makes "I don't know who consumes this" an explicit output**, which is the honest state most of the time and the one humans most need to hear.

## Origin

An assistant adding a helper to an internal `@org/common` package also upgraded its HTTP dependency across a major version, "to stay current." The package's tests passed and it shipped as a patch release. Six services auto-picked it up within a week. Two failed CI on peer conflicts; one deployed and started throwing on a removed option at runtime. Three teams filed three separate incidents before anyone connected them to a one-line `package.json` change in a library none of them had touched.
