### No Wildcard Version Ranges

NEVER declare a dependency with an unbounded version: no bare names in requirements.txt, no `*`, no `latest`, no open-ended `>=x` without an upper bound. Every dependency you add gets a bounded constraint anchored to the version you actually installed and tested.

- After installing, record what you got. JS: keep the caret range the package manager writes (`^4.2.1`) and ensure the lockfile is committed. Python without a lockfile-based tool: write `requests>=2.32,<3` or pin exact (`==2.32.3`) in requirements.txt — never a bare `requests`.
- Anchor to reality: the lower bound is the version you tested, not `0` and not a guess. Run `pip show <pkg>` / `npm ls <pkg>` to read the installed version instead of inventing one.
- The upper bound is the next major. Majors are documented breakage; an unbounded range pre-approves breakage sight unseen.
- If the project uses a lockfile tool (npm, pnpm, poetry, uv, cargo, bundler), the lockfile provides exactness — the manifest range can stay flexible, but it still must not be `*` or `latest`, because the manifest is what governs the next re-resolution.
- When generating a manifest for example code or a scaffold, pin there too. Scaffolds get copied into production verbatim.

**Red flags that you're about to violate this:**
- "I'll leave the version off so it always gets the newest."
- "latest keeps the project up to date automatically."
- "I don't know the current version, so an open range is safer."
- "This is just a quick script; versioning it is ceremony."
- "The README's install command doesn't specify a version either."
