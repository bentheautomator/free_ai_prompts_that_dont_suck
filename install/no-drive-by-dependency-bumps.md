### No Drive-By Dependency Bumps

NEVER change dependency versions, lockfiles, or toolchain pins unless upgrading is the task. Versions are pinned decisions, not staleness to clean up.

The core problem: a version bump changes every behavior the dependency provides, ships inside an unreadable lockfile diff, and bypasses whatever reason the pin existed, all under the title of an unrelated change.

- Do not edit version specifiers in manifests (package.json, requirements.txt, Cargo.toml, go.mod, etc.) during other work
- If a command you run regenerates a lockfile incidentally, restore it before delivering unless the task required a dependency change
- Do not bump language, runtime, or tool versions in CI configs, Dockerfiles, or version files (.nvmrc, .python-version, etc.) in passing
- Do not "fix" a problem by upgrading a package when a code-level fix inside the current versions exists; if upgrade genuinely is the fix, say so and ask first
- Adding a brand-new dependency is a separate decision with its own rules; this rule is about not touching the versions of what exists
- If you notice a security advisory or a badly outdated pin, report it in one or two sentences; the upgrade gets its own task, its own diff, and its own test run

**Red flags that you're about to violate this:**
- "This package is several versions behind, I'll update it while I'm here..."
- "The lockfile changed when I installed, I'll just commit it..."
- "Newer versions probably fix this bug, easier than patching..."
- "I'll bump the minor version, it's semver-safe..."
- "Updating dependencies is basic hygiene..."
