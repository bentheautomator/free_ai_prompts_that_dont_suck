---
title: No Library Swaps Disguised as Refactors
slug: no-library-swaps-disguised-as-refactors
category: refactoring
tags: [universal, refactoring, dependencies]
works_with: all
severity: high
one_liner: "Stops dependency replacements smuggled in as part of code cleanup"
---

# No Library Swaps Disguised as Refactors

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from replacing one library with an "equivalent" one mid-refactor, importing a thousand subtle behavior differences as a side effect.

**[Copy-paste ready version](../../install/no-library-swaps-disguised-as-refactors.md)** — just the instruction block, no explanation.

## The Problem

Somewhere in the middle of a cleanup, the assistant decides the codebase's date library is outdated and migrates the file it's touching to the newer, better one. Or it replaces `lodash` calls with "native equivalents," swaps the HTTP client for the one it prefers, or trades the project's YAML parser for a different package. Each swap is presented as part of the refactor, each is justified by genuine community consensus, and each replaces a battle-tested set of behaviors with a *similar* set. Similar is the problem. The old date library parsed ambiguous strings leniently and the new one throws; `_.get` returns `undefined` for broken paths while the hand-rolled native version throws on null prototypes; the old HTTP client retried on connection reset and the new one doesn't. None of this is in the function signatures. All of it is behavior.

Models do this because library preferences are strongly represented in their training data ("stop using X, use Y") and because, mid-refactor, every line is already up for regeneration, so the import line doesn't feel special. But a dependency swap is a migration project with its own risk surface: edge-case parity, error-behavior parity, performance characteristics, transitive dependencies, bundle size. Folding it silently into a refactor means running that project with zero of its diligence.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No Library Swaps Disguised as Refactors

NEVER replace a library, framework utility, or dependency with a different one as part of a refactor. Restructuring code means reshaping it around the dependencies it already has. Swapping a dependency is a migration, a separate project with its own verification, and it requires the user's explicit go-ahead.

"Equivalent" libraries are equivalent on the happy path and divergent at the edges: parsing leniency, null handling, timezone behavior, retry semantics, thrown vs returned errors.

- Keep every existing import doing its existing job. Refactor the code around `moment`, `lodash`, `requests`, or whatever the file already uses, even if you consider the library outdated, deprecated, or unfashionable.
- "Replace with native equivalents" is a swap too: hand-rolled replacements for library calls (`_.get`, `_.cloneDeep`, `moment().format`) must reproduce edge-case behavior the library spent years accumulating, which a fresh five-liner does not.
- Do not add new dependencies during a refactor either; a refactor's dependency footprint is identical before and after, in both directions.
- Do not bump dependency versions as part of cleanup. Version bumps change behavior on someone else's schedule and belong in their own change.
- If a dependency genuinely deserves replacing (deprecated, unmaintained, security advisories), say so in your summary as a recommendation, with the specific evidence, and let the user schedule the migration. A real migration gets parity tests for the edge behaviors; a smuggled one gets incidents.
- Exception: if the user explicitly asked for the swap, it's the task, not a refactor; do it as a dedicated change with before/after behavior checks on the call sites that exercise edge cases.

**Red flags that you're about to violate this:**

- "This library is deprecated; I'll migrate to the modern one while refactoring."
- "Native array methods can replace all these lodash calls."
- "The newer client has a cleaner API, so the refactored code should use it."
- "It's a drop-in replacement, the APIs are nearly identical."
- "I'll also bump this dependency since I'm touching the file."

---

## Why It Works

1. **It reclassifies the swap as a migration, not an edit.** The model treats an import line as just another line; naming the hidden project (parity testing, edge-case audit, transitive deps) attaches the true cost to the decision point.
2. **"Equivalent on the happy path, divergent at the edges" preempts the drop-in claim.** That claim is the precise rationalization that precedes every bad swap; discrediting it in advance with concrete divergence categories (parsing, nulls, retries) makes it harder to assert reflexively.
3. **It covers the native-rewrite loophole.** Models that wouldn't add a dependency will happily delete one and hand-roll its behavior, which is the same risk wearing virtue; explicitly equating the two closes the gap.
4. **The recommendation channel respects the model's often-correct judgment.** The library frequently *is* outdated; letting that observation become a scheduled migration with diligence, rather than suppressing it, keeps the rule aligned with good engineering.

## Origin

While refactoring a report scheduler, an assistant replaced the project's date library with a modern alternative, "a drop-in replacement." The old library treated an undefined timezone as the configured default; the new one treated it as UTC. Every customer whose timezone field was legacy-blank started receiving reports shifted by their UTC offset, which for some meant the *previous* day's report. It took eleven days and one very patient enterprise customer to trace daily-report drift back to a refactor that "didn't change any logic."
