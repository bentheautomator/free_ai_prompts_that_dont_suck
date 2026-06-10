---
title: List the Files Before a Multi-File Change
slug: list-the-files-before-a-multi-file-change
category: planning
tags: [universal, planning]
works_with: all
severity: medium
one_liner: "Multi-file changes navigated by discovery instead of by manifest"
---

# List the Files Before a Multi-File Change

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents starting a multi-file change without first enumerating which files it touches.

**[Copy-paste ready version](../../install/list-the-files-before-a-multi-file-change.md)** — just the instruction block, no explanation.

## The Problem

A change that spans files gets executed like a treasure hunt: edit the first file, see what breaks or what it references, follow that to the second file, discover a third along the way. The file list is assembled by stumbling through the change rather than known before it. This works, sort of, the way navigating without a map works — until a turn gets missed. The edit-and-follow method finds files connected by imports and compile errors; it routinely misses the ones connected by convention: the fixture that mirrors the schema, the docs example, the second implementation of the interface, the config template, the mobile counterpart of the web component.

The misses have a signature: everything compiles, tests mostly pass, and the unedited file surfaces later as drift — a fixture testing the old shape, documentation lying about a parameter, one of two parallel implementations now behaving differently. Meanwhile, the discovered-as-you-go ordering also wrecks the work's reviewability and estimability: nobody, including the assistant, knew if this was a four-file or fourteen-file change until it was over.

The manifest costs a few minutes of searching before the first edit: grep for the symbol, the string, the concept; check the conventional mirror locations; write the list down. Then the change executes against a known map, and "done" means the list is crossed off — not "nothing else broke that I noticed."

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### List the Files Before a Multi-File Change

ALWAYS enumerate the files a multi-file change will touch before making the first edit. The list is the map; editing without it means discovering the change's extent by stumbling through it, and the files you stumble past stay wrong.

The core problem: follow-the-imports discovery finds files connected by the compiler and misses files connected by convention — fixtures, docs, templates, parallel implementations — which then drift silently.

- Before the first edit, search for everything the change touches: the symbol name, the string literal, the route, the concept. Multiple searches, not one.
- Explicitly check the conventional mirrors that searches under-find: test fixtures, seed data, documentation examples, config templates, generated-code inputs, sibling platforms (web/mobile/CLI), and any "the other place we do this."
- Write the manifest down with one phrase per file: "`models/user.py` — add field; `fixtures/users.json` — add field to all records; `docs/api.md` — update example."
- A surprise file mid-change is fine — add it to the manifest *and ask what else the search missed*, since one miss usually has siblings.
- Done means the manifest is fully crossed off. An uncrossed entry is unfinished work, not an optional extra.

**Red flags that you're about to violate this:**
- "I'll find the affected files as I go..."
- "The compiler will tell me what else needs changing..." (not the JSON fixture it won't)
- "It's probably just these two files..."
- "I'll grep once for the function name, that should cover it..."
- "Tests pass, so I must have gotten everything..."

---

## Why It Works

1. **It uses search to find what execution can't.** Compile errors reveal only statically-linked dependents; greps over names, strings, and concepts reach the convention-linked files — fixtures, docs, templates — that the edit-and-follow loop structurally skips.

2. **It converts "done" into a checklist.** Without a manifest, completion is the feeling of nothing else breaking. With one, completion is an objective property — every entry crossed off — and an unedited file is a visible omission instead of a future bug.

3. **It treats a surprise as evidence of more surprises.** Files missed by the initial search were missed *for a reason* — a naming variation, an unexpected location — and that reason usually applies to siblings. Re-searching on the first surprise catches the family, not just the one.

## Origin

A field rename was executed by following the type errors: model, serializer, three handlers, done — clean build, green unit tests. Unlisted and unedited: the JSON fixtures used by the integration suite (which ran nightly, not on the branch) and a partner-facing docs page with a copy-paste request example. The nightly suite went red the next morning; the docs page was found by a partner whose integration broke, three weeks later. A five-minute grep for the old field name as a *string* — not a symbol — had matched both files all along.
