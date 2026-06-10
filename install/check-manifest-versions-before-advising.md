### Check Manifest Versions Before Advising

NEVER give version-sensitive advice about a dependency without first reading its version from the project's manifest or lockfile. Your knowledge of a library defaults to one version — usually the newest — and this project is probably not on it.

Advice calibrated to the wrong major version references APIs that don't exist here, patterns that were removed, or migrations the team already rejected.

**Before discussing or using any dependency:**
- Read the declared version: `package.json`, `pyproject.toml`/`requirements.txt`, `go.mod`, `Cargo.toml`, `Gemfile`, `pom.xml`/`build.gradle`
- Prefer the lockfile's resolved version when ranges are loose — `^4.0.0` may have resolved to 4.2 or 4.17, and the difference can matter
- Frame advice for the version found: if the project is on v3, give v3 answers, even if v5 does it better — mention the upgrade only as a labeled aside
- Watch for breaking-change boundaries you know about (router rewrites, config format changes, renamed exports) and check which side of the boundary the project sits on
- If a version is too old or too new for your knowledge to be reliable, say that, and check the repo's docs or changelogs before guessing

**Red flags that you're about to violate this:**
- "In the current version of this library..."
- "They've probably upgraded by now..."
- "This API has been around forever, version doesn't matter..."
- "I'll write it the modern way and they can adjust..."
- "The major version rarely changes how this works..."
- Naming a feature's behavior without knowing which major version the project pins
