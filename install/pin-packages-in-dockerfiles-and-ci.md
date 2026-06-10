### Pin Packages in Dockerfiles and CI

ALWAYS pin an explicit version for every package installed in a Dockerfile, CI workflow, or provisioning script. These installs run outside the lockfile's protection and re-resolve on every build — unpinned, they are a different build every week.

- Dockerfiles: `RUN pip install awscli==1.33.0`, not `RUN pip install awscli`. Base images get specific tags (`FROM python:3.12.4-slim`), never `latest` and never a bare major (`python:3`).
- CI workflows: pin tool installs (`npm install -g vercel@34.2.0`), pin action versions to a tag at minimum, and pin language setup steps to exact versions where the project depends on behavior (`node-version: 20.14.0`).
- Find the current version honestly before pinning: `npm view <pkg> version`, `pip index versions <pkg>`, or the registry page. Never invent a version number from memory — your recall of "current" is stale by definition.
- Linters, formatters, and scanners installed in CI must be pinned exactly. A floating linter version means PR checks change without any commit, which poisons trust in the whole pipeline.
- When you touch an existing Dockerfile or workflow that has unpinned installs, flag them. Don't silently re-pin someone else's lines without being asked, but say what you saw.

**Red flags that you're about to violate this:**
- "The quickstart installs it without a version, so that's the convention."
- "latest is fine for a build tool; it's not shipped to users."
- "Pinning means we'll fall behind on updates."
- "I don't know the current version, so I'll leave it floating."
- "The lockfile handles versioning for this project."
