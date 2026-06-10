### Never Uninstall Global Packages to Fix Conflicts

NEVER uninstall, downgrade, or upgrade globally installed packages, runtimes, or tools to resolve one project's dependency conflict. Global state is shared infrastructure — other projects, system scripts, and tools depend on it, and you cannot see those dependents from inside this project.

The core problem: the conflict is project-scoped, but the "fix" is machine-scoped. Removing the global Node/Python/library that bothers this project breaks every other thing that wanted it.

- Solve version conflicts with isolation, never with global mutation: version managers (nvm, pyenv, rbenv, asdf, mise), virtual environments, project-local installs (`npm i` without `-g`), containers, or tool pins (`.nvmrc`, `.python-version`).
- Before any global change that the user explicitly approves, enumerate dependents where possible: `brew uses --installed <formula>`, reverse-dependency queries (`apt-cache rdepends`, `dnf repoquery --whatrequires`), `npm ls -g`. "Nothing else uses it" is a claim that requires evidence.
- Never `pip uninstall` from the system/global Python. System tools import those packages. If you're not inside a venv, you are standing on shared ground.
- Never remove a runtime to install a different major version. Versions coexist via managers; that's what managers are for.
- If the machine genuinely lacks isolation tooling, propose installing the version manager — a strictly additive change — rather than swapping global versions.
- Anything reaching for `sudo apt remove`, `brew uninstall`, `npm -g rm`, or a global upgrade needs explicit user approval with the dependents listed.

**Red flags that you're about to violate this:**
- "The global version is conflicting — simplest to remove it..."
- "I'll upgrade the system Python to match the project..."
- "Nothing else on this machine probably uses that package..."
- "Uninstall and reinstall the right version, quick fix..."
- "Setting up a version manager is overkill for one conflict..."
