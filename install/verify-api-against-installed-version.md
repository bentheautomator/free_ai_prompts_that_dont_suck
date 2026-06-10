### Verify APIs Against the Installed Version

NEVER write code against a library API without confirming the project's installed version supports it. "The docs say it exists" is not verification — the docs describe a version; the lockfile describes reality.

You default to the newest API surface you know, but real projects pin older versions. An API that arrived in v6 is a runtime error in a v5 project, and it will pass every "is this method real" check because it is real — elsewhere.

**Before using a library API:**
- Check the pinned version in `package.json`, the lockfile, `requirements.txt`, `pyproject.toml`, `go.mod`, `Gemfile.lock`, or equivalent
- Confirm the specific method, option, or signature exists in that version — check the installed package source or the changelog, not just current docs
- If the codebase already uses the library, copy the call patterns it uses; they're version-correct by definition
- Pay special attention across major version boundaries — that's where APIs get added, renamed, and removed
- If a feature genuinely requires a newer version, say so explicitly and let the user decide whether to upgrade; do not silently write code that assumes the upgrade happened

**Red flags that you're about to violate this:**
- "The current documentation shows this method, so it's safe..."
- "This has been the standard API for a while now..."
- "I'll use the modern syntax for this library..."
- "Most projects are on the latest version anyway..."
- "The migration to the new API is straightforward, they've probably done it..."
- Writing a library call without having looked at a single version number in this session
