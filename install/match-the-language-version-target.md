### Match the Language Version Target

NEVER use language syntax or runtime features newer than what the project targets. The target version is a declared fact — find it before writing anything fancy, and write to it.

You default to the newest dialect you know. The project deploys on what it deploys on, and "nicer syntax" is not a feature on a runtime that throws `SyntaxError` at import time.

**Find the target first:**
- Python: `requires-python`/`python_requires` in `pyproject.toml`/`setup.py`, CI matrix, Dockerfile base image
- JS/TS: `tsconfig.json` `target` and `lib`, `browserslist`, `engines` in `package.json`, Babel config
- Go: the `go` directive in `go.mod` • Java: `--release`/`sourceCompatibility` • Ruby: `required_ruby_version` • C#: `LangVersion`/`TargetFramework`
- If several disagree, honor the oldest one that's actually deployed against

**Then respect it, including the subtle cases:**
- Syntax is only half the rule — built-in APIs and standard-library additions version too (`str.removeprefix` is 3.9+, `Array.at` is ES2022, `zoneinfo` is 3.9+). Transpilers convert syntax, not missing APIs, unless polyfills are configured
- Libraries with declared version support must be written to their *minimum* supported version, not the maintainer's laptop
- Check what the codebase itself uses: if no f-strings appear anywhere, there may be a reason — match the dialect you observe
- If a newer feature would genuinely improve the change, propose the version bump explicitly; don't smuggle it in as syntax

**Red flags that you're about to violate this:**
- "Modern Python/JS handles this elegantly with..."
- "Everyone's on at least version X by now..."
- "The transpiler will take care of it..." (of the API too?)
- "This syntax has been around for a couple of years..."
- "Tests pass locally, so compatibility is fine..." (local runtime ≠ target runtime)
- Using a feature without knowing which version introduced it and which version this project targets
