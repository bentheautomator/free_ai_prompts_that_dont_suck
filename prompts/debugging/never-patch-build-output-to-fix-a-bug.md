---
title: Never Patch Build Output to Fix a Bug
slug: never-patch-build-output-to-fix-a-bug
category: debugging
tags: [universal, debugging]
works_with: all
severity: high
one_liner: "AI fixing bugs by editing dist/, node_modules/, or generated files"
---

# Never Patch Build Output to Fix a Bug

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from fixing a bug by editing compiled output, vendored dependencies, or generated files — fixes that evaporate on the next build.

**[Copy-paste ready version](../../install/never-patch-build-output-to-fix-a-bug.md)** — just the instruction block, no explanation.

## The Problem

The stack trace points into `dist/app.bundle.js`, so the AI edits `dist/app.bundle.js`. The bug is in a generated API client, so it edits the generated client. The broken function lives in `node_modules/some-lib/lib/index.js`, so that's where the patch lands. In every case the fix works — right now, in this checkout — and is already doomed: the next `npm install`, the next codegen run, the next build wipes it without a trace. The bug "mysteriously returns," except there's no mystery: the fix was written in sand below the high-tide line.

The AI does this because it debugs by proximity: the error names a file, the file is editable, so the file gets edited. What's missing is the concept of *derived* artifacts — that some files are outputs of a pipeline (compiler, bundler, code generator, package manager) and editing an output is like correcting a photocopy. The correct edit site is always upstream: the source that compiles into dist/, the schema or spec the generator consumes, the template the scaffold came from, or — for a genuinely buggy dependency — the dependency's declared version, a patch-file mechanism, or an upstream fix.

The sneaky cost is the intermediate period: the hand-patched artifact works on the machine where it was edited, passes local testing, and then regresses for whoever builds fresh — producing "works on my machine" reports that burn days, since nobody suspects that `dist/` and source have quietly diverged.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Patch Build Output to Fix a Bug

NEVER fix a bug by editing a derived artifact: compiled output (`dist/`, `build/`, `target/`, `.next/`), installed dependencies (`node_modules/`, `vendor/`, site-packages), generated code (codegen clients, protobuf stubs, migration snapshots), or lockfiles by hand. Derived files are outputs of a pipeline; edits to them are erased by the next run of that pipeline.

Before editing any file during debugging, determine: is this file authored, or produced? Produced files have an upstream, and the fix belongs there.

- Recognize the markers: `// auto-generated, do not edit` headers, paths in `.gitignore`, minified/bundled content, generator output paths, anything under a package manager's control
- When a trace points into a derived file, map it back to its source (source maps, the generator's input schema, the dependency's repo) and fix there — then re-run the pipeline and confirm the fix survives regeneration
- For a bug in a third-party dependency: prefer (in order) using the API correctly, upgrading to a fixed version, a documented patch mechanism (`patch-package`, pnpm patches, a vendored fork with a README), reporting upstream — never silent edits inside `node_modules/`
- For generated code that's wrong: fix the schema, spec, or generator config it's produced from; if the generator itself is buggy, that's the bug to address
- The post-fix test is regeneration: rebuild/reinstall/regenerate, then verify the fix survived and the bug is still gone; a fix that can't survive the pipeline was never a fix
- Editing a derived file "just temporarily to confirm the theory" is fine — but say so, and treat the upstream edit as the actual deliverable

**Red flags that you're about to violate this:**
- "The error is in dist/, so I'll correct it there..."
- "I'll fix this directly in node_modules to unblock things..."
- "This generated file has the bug; editing it is the fastest path..."
- "I'll hand-adjust the lockfile to resolve the conflict..."
- Editing a file with an auto-generated header without reading the header
- A fix that works locally and has no explanation for how it survives the next build

---

## Why It Works

1. **It installs the authored/produced distinction.** The AI's proximity-based editing has no concept of derivation; making "is this file an output?" a mandatory pre-edit question catches the entire class before the first keystroke.

2. **It defines the survival test.** "Regenerate, then verify" is an objective check that hand-patched artifacts always fail — turning the doomed fix from a future mystery into an immediate, visible failure.

3. **It provides the legitimate dependency path.** Real third-party bugs exist; the ordered escalation (use correctly → upgrade → patch mechanism → upstream) gives the AI a sanctioned route, so the ban doesn't get bypassed out of necessity.

4. **It tolerates diagnostic edits honestly.** Temporarily hacking dist/ to confirm a theory is legitimate technique; requiring the disclosure and the upstream deliverable keeps the diagnostic from quietly becoming the fix.

## Origin

An assistant fixed a date-serialization bug by editing the generated API client directly — clean change, tests passed, shipped. Two weeks later a teammate regenerated the client to pick up a new endpoint, silently erasing the fix; the bug returned in production with no related code change in the diff, which made it nearly impossible to trace. The hunt consumed two days, ending when someone diffed the regenerated client against git history and found the orphaned fix. The real edit — one line in the OpenAPI spec's date format — took five minutes.
