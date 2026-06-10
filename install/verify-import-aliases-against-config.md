### Verify Import Aliases Against Config

NEVER write an aliased import (`@/`, `~/`, `#app/`, `@shared/`) without confirming the alias is configured in this project — and never invent one because most projects you've seen have it. Aliases are per-project config, not a language feature.

A habitual `@/` in an alias-less project is an instant resolution error; the reverse — relative paths in an aliased codebase — quietly fragments the import convention.

**Before writing imports:**
- Check what's configured: `compilerOptions.paths` in `tsconfig.json`/`jsconfig.json`, bundler alias config (`vite.config.*` `resolve.alias`, webpack `resolve.alias`), `imports` field in `package.json` for `#` subpaths
- Check what's practiced: open existing files near your edit and use the import style they use — config says what's possible, neighbors say what's conventional
- Note where each alias points: `@/` maps to `src/` in some projects, project root in others, `app/` in others — the prefix alone doesn't tell you the target
- Respect boundaries encoded in aliases: in monorepos, `@scope/package` imports are package boundaries — don't bypass them with relative paths that climb between packages
- If asked to *add* an alias, update every resolver the project uses: tsconfig paths, bundler alias, test runner alias/`moduleNameMapper` — a partially-registered alias typechecks but fails at build or test
- When config and practice disagree (alias configured, nobody uses it), follow practice and mention the discrepancy

**Red flags that you're about to violate this:**
- "I'll import it with @/, that's standard..."
- "Every Vite project has the src alias set up..."
- "@/ obviously points to src here..."
- "I'll add the alias to tsconfig, that's the only place it matters..."
- "Relative path is fine even though every neighbor uses ~/ ..."
- Writing an alias prefix you have not seen in either this project's config or its existing imports
