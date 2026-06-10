---
title: Verify Doc Code Examples Actually Run
slug: verify-doc-code-examples-actually-run
category: documentation
tags: [universal, docs, examples]
works_with: all
severity: high
one_liner: "Code examples in docs that no longer compile or run against the real API"
---

# Verify Doc Code Examples Actually Run

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents documentation code examples that look plausible but fail the moment someone pastes them.

**[Copy-paste ready version](../../install/verify-doc-code-examples-actually-run.md)** — just the instruction block, no explanation.

## The Problem

Code examples in docs occupy a blind spot: they're code, but nothing executes them. The compiler never sees them, the test suite never runs them, and the AI that writes them treats them as prose with syntax highlighting. So the example calls `client.connect(host, port)` when the actual signature takes a config object, imports from a module path that was reorganized two releases ago, or uses a method name the model remembered from a different library entirely.

The consequence is uniquely corrosive because examples are the part of the docs people actually use. A reader who pastes a broken example doesn't think "stale docs" — they think they made a mistake, and they spend an hour debugging their own correct setup against your incorrect example. Broken examples convert your most engaged readers into your most frustrated ones.

AI assistants produce these constantly because example code is generated from the model's general knowledge of how such APIs *usually* look, not from the repo's actual exports. Writing a plausible example takes one pass; writing a correct one requires checking real signatures, real import paths, and real defaults — work the model skips unless told the example is code with obligations, not decoration.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Verify Doc Code Examples Actually Run

NEVER put a code example in documentation that you haven't checked against the real code. Every example is a claim that "this exact text works" — treat it with the same rigor as code you ship.

The core problem: examples are generated from how APIs usually look, not how this one actually looks, and nothing automated catches the difference.

Rules:
- Before writing an example, read the actual function signature, the actual export, the actual import path. Don't write the call from memory
- If the project has runnable doc tests (doctest, mdbook test, examples/ directory in CI), put the example where it gets executed
- If it can't be executed, verify it manually: do the imports resolve, do the names exist, do the argument types match, does the shown output match what the code returns
- When editing code that an existing doc example uses, update the example in the same change — search the docs for the old names
- Copy real working code into examples and trim it down; don't compose examples from scratch and hope
- Show real output, not invented output. If the example prints something, run it or trace it

**Red flags that you're about to violate this:**
- "This is how this kind of API usually works..."
- "It's just an illustrative snippet, it doesn't need to be exact..."
- "The reader will adapt it to their setup anyway..."
- "Checking the actual signature is overkill for a doc example..."
- "I'll write the output it probably produces..."
- "The old example was probably correct, I'll extend it..."

---

## Why It Works

1. **It reclassifies examples from prose to code.** The model applies verification effort by artifact type, and examples default to the prose tier. Stating "an example is a claim that this exact text works" moves them into the tier where checking signatures is mandatory.

2. **It names the generation shortcut.** Examples fail because they're sampled from the model's prior over similar APIs. Explicitly requiring "read the actual signature first" replaces sampling with lookup.

3. **It prefers extraction over composition.** Trimming real working code down to an example inherits correctness; composing from scratch inherits nothing. The directionality matters and the instruction states it.

4. **It pushes toward executable docs.** Where doctest-style infrastructure exists, routing examples into it converts a one-time check into a permanent regression guard.

## Origin

A client library's README quickstart, refreshed by an assistant during a docs cleanup, showed `Client(api_key=...)` — the constructor pattern from the library's most popular competitor. The actual library used a module-level `configure()` call. The example was syntactically perfect, idiomatically standard, and wrong. Support traced a month of "authentication failed" tickets to it; every affected user had followed the quickstart exactly, which was precisely the problem.
