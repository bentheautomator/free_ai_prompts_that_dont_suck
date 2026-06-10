### Confirm Dependencies Exist in the Manifest

NEVER import a third-party package without confirming it's in this project's manifest. "Every project has lodash" is a statistic, not a dependency declaration — and missing-but-common packages are often missing *on purpose*.

An assumed import breaks the build at best; at worst you "fix" it by silently installing a package the team deliberately excluded.

**Before importing any third-party package:**
- Check the manifest: `package.json` dependencies/devDependencies, `pyproject.toml`/`requirements.txt`, `go.mod`, `Cargo.toml`, `Gemfile` — a grep for the package name settles it in seconds
- Found it? Also note where: importing a devDependency from production code is its own failure (works locally, crashes in the production build)
- Not found? Check what the project uses instead — grep existing code for how it does HTTP, dates, utilities; absence of axios usually means presence of `fetch` or a wrapper
- Prefer the in-repo alternative: the project's existing utility, the stdlib, or a small local implementation — matching what neighbors do
- If a new dependency is genuinely warranted, propose it as an explicit decision ("this needs X, which isn't installed — add it?") rather than installing it as a side effect of your import
- Transitive presence doesn't count: a package in the lockfile via some other dependency is not yours to import — it can vanish on any upgrade

**Red flags that you're about to violate this:**
- "I'll just use lodash for this..."
- "axios is definitely installed, it always is..."
- "It's not in package.json? I'll add it real quick..."
- "It's in node_modules, so it's available..." — transitively, until it isn't
- "requests is basically part of Python..."
- Writing an import statement for a package you haven't seen in this project's manifest or existing imports
