---
title: List the Directory Before Assuming Layout
slug: list-the-directory-before-assuming-layout
category: context
tags: [universal, assumptions, grounding]
works_with: all
severity: high
one_liner: "AI navigating an imagined src/components tree instead of the real layout"
---

# List the Directory Before Assuming Layout

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from operating on a project structure it imagined instead of the one on disk.

**[Copy-paste ready version](../../install/list-the-directory-before-assuming-layout.md)** — just the instruction block, no explanation.

## The Problem

Before reading a single directory listing, the AI already "knows" the project's shape: `src/` with `components/`, `services/`, `utils/`; tests in `tests/` or `__tests__/`; config at the root. This phantom layout is a composite of every scaffold in its training data, and the AI navigates it like a map — searching imagined directories, planning file moves between folders that don't exist, describing "your services layer" to a project organized by feature instead of by layer.

The real project might be a monorepo with everything under `packages/`, a Go project with `cmd/` and `internal/`, a Django app organized by domain, or a fifteen-year-old codebase whose structure follows no scaffold ever published. Operating on the phantom map produces searches that miss (the AI greps `src/` while the code lives in `app/`), plans that don't apply ("move it to the services folder" — which one? there isn't one), and explanations that describe a generic project instead of this one.

The map is one command away. A root listing plus one level of depth corrects the entire phantom — but it has to actually run before the navigation starts.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### List the Directory Before Assuming Layout

NEVER reason about this project's structure from the layout in your head. The structure you expect is a composite of training-data scaffolds; the structure that exists is one `ls` away, and they agree less often than you think.

A phantom layout corrupts everything downstream: searches scoped to wrong directories, plans referencing folders that don't exist, explanations of an architecture nobody built.

**Operating rules:**
- Begin structural work with a real listing: project root, then the relevant subtree (`ls`, tree-style listing, or a broad glob) — before forming opinions about organization
- Determine the actual organizing principle from what you see — by layer (`controllers/`, `models/`), by feature (`billing/`, `auth/`), by package (`packages/*`, `apps/*`), language-conventional (`cmd/`, `internal/`, `pkg/`) — and use that vocabulary, not your default one
- When a search comes up empty, suspect your path scope before concluding the code doesn't exist — re-search from the root
- Don't describe directories you haven't listed: "your components folder" is a claim, and it's false in every project that organizes differently
- Before planning file creation or moves, verify the destination directory exists and check what already lives there

**Red flags that you're about to violate this:**
- "The components will be in src/components..."
- "Standard layout — I know where everything is..."
- "I searched src/ and found nothing, so it doesn't exist..."
- "I'll put this in the utils folder" — unseen
- "Projects like this keep their tests in a top-level tests directory..."
- Describing the project's organization in a session containing zero directory listings

---

## Why It Works

1. **It gives the phantom a name.** Calling the expected layout "a composite of training-data scaffolds" lets the AI recognize that its mental map has an origin — and that the origin isn't this repo.

2. **It links empty searches to scope errors.** "Found nothing" in a wrongly-scoped search reads as "doesn't exist" — the most damaging downstream effect. Rerouting that conclusion to "re-check from root" catches the phantom at its most expensive moment.

3. **It forces vocabulary alignment.** Requiring the project's own organizing terms (feature vs layer vs package) prevents the subtler failure where the AI lists directories but keeps narrating in scaffold-speak.

4. **It puts a checkpoint before creation and moves.** Structure errors do the most permanent damage when files get created in invented locations; verifying the destination converts that from a guess to an observation.

## Origin

Asked to find and fix a flaky retry helper, an AI searched `src/utils/` and `src/lib/`, found nothing, and reported the helper "doesn't exist — I'll create it." The project was a feature-organized monorepo; the helper lived at `packages/core/retry/`. The AI's new duplicate shipped with subtly different backoff behavior, and for a month the codebase retried two different ways depending on which import a given file happened to use. The deduplication PR was titled "there can be only one."
