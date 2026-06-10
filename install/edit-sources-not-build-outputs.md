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
