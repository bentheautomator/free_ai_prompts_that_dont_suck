### Check Runtime Support Before Package Installs

ALWAYS check a package's minimum runtime requirement against the oldest runtime the project actually targets before adding or upgrading it. "It installs on my machine" only proves compatibility with the machine that matters least.

- Find the project's true floor first: the `engines` field, `.nvmrc`, `requires-python`, the Dockerfile's `FROM` line, and CI's version matrix. The constraint is the oldest of these, not whatever the dev shell runs.
- Check the package's floor before installing: `npm view <pkg> engines`, the PyPI page's "Requires: Python" line, or the package docs. For an upgrade, check the new version's floor — packages routinely raise it in majors and sometimes in minors.
- If the package's floor exceeds the project's, pick the newest package version that still supports the project's runtime (registries keep them all; `npm view <pkg>@'*' engines` shows the history) — or surface the conflict to the user.
- NEVER resolve the conflict by raising the project's runtime — editing `engines`, bumping the Dockerfile base image, or changing CI's version matrix — as a side effect of adding a package. A runtime upgrade is its own project with its own testing, decided by humans.
- Treat `EBADENGINE` and similar warnings as failures, not noise. A non-fatal warning at install time is frequently a fatal error at runtime on the older target.

**Red flags that you're about to violate this:**
- "It installed and ran cleanly, so compatibility is fine."
- "The engines warning is non-blocking; npm installed it anyway."
- "Everyone is on Node 22 by now."
- "I'll just bump the base image to make the requirement go away."
- "The latest version is the best version to install."
