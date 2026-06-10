---
title: Edit Sources, Not Build Outputs
slug: edit-sources-not-build-outputs
category: file-handling
tags: [universal, files, build]
works_with: all
severity: high
one_liner: "Stops fixes from landing in dist/ and minified bundles the next build deletes"
---

# Edit Sources, Not Build Outputs

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents bug fixes from being applied to compiled, bundled, or minified artifacts instead of the source files that produce them.

**[Copy-paste ready version](../../install/edit-sources-not-build-outputs.md)** — just the instruction block, no explanation.

## The Problem

The user reports a bug, the assistant greps for the error string, and the top hit is `dist/app.min.js` or `build/main.css` — because that's where the string actually executes from. So the assistant edits it. The fix even works, briefly: the page reloads, the bug is gone. Then anyone runs `npm run build` and the artifact is regenerated from the untouched source, resurrecting the bug. If `dist/` is gitignored, the fix never even left the machine; if it's checked in (docs sites, GitHub Pages, some legacy setups), source and artifact now disagree and the repo lies about what's deployed.

Minified files add a second failure: a hand edit to a bundle with a sourcemap desynchronizes the map, so every stack trace afterward points at the wrong original line. Grep can't tell sources from outputs — both contain the string — and assistants follow the grep hit. The artifact is where the symptom is; the source is where the bug is.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Edit Sources, Not Build Outputs

NEVER edit build outputs. If a grep hit lands in `dist/`, `build/`, `out/`, `target/`, `.next/`, `public/assets/`, a `*.min.*` file, or anything with a sourcemap comment, the edit belongs in the source that generates it.

A fix applied to an artifact lasts exactly one build. Then it's gone, and the bug is back with your name nearby.

- Identify outputs before editing: output directories above; minified or single-line files; files referenced by `// sourceMappingURL`; compiled forms of adjacent sources (`.js` next to the `.ts` that produces it, `.css` next to `.scss`).
- Trace the hit back: search the same string (or its unminified equivalent) under `src/`, check the build config (`webpack.config.js`, `vite.config.ts`, `tsconfig.json` `outDir`) to learn what compiles to where.
- Fix the source, run the build, verify the output changed. If the output is checked in, commit the regenerated artifact together with the source change — never the artifact alone.
- If the string exists only in the artifact and nowhere in source, the source is generated elsewhere (a dependency, a CMS, codegen) — find it, don't patch the bundle.
- Exclude output dirs from your searches up front (`grep -r --exclude-dir=dist --exclude-dir=build`, or rely on `.gitignore`-aware search) so the tempting wrong answer never appears.

**Red flags that you're about to violate this:**

- "The grep hit is in dist/, I'll fix it right there."
- "Editing the bundle is faster than running the build."
- "I'll patch the minified file carefully; it's just one string."
- "The .js file is right next to the .ts file, I'll edit whichever."
- "It works after my edit, so the fix is in the right place."

---

## Why It Works

1. **It severs the grep-hit-to-edit reflex at the exact junction it fails.** Search ranks by match, not by authorship; an explicit output-directory list gives the assistant a reason to distrust the top hit.
2. **"It works after my edit" is dismantled as evidence** — the rule explains why the verification passes while the fix is still wrong, which is the trap that makes this failure self-concealing.
3. **The compiled-twin check (`.js` beside `.ts`) catches the subtlest case**, where the artifact lives in the same directory as its source and no path pattern flags it.

## Origin

A typo fix for a customer-visible error message was applied to `dist/bundle.js` on a Friday and verified in the browser. Monday's release build regenerated the bundle from the unchanged source. The customer reopened the ticket with "still broken," the engineer swore it was fixed and had the screenshot to prove it, and a half-day of confusion ended at `git log dist/` showing the fix had never touched source.
