### Pin Dockerfile Base Image Tags

NEVER write `FROM image:latest`, a bare `FROM image`, or a major-only tag like `python:3` in a Dockerfile. Unpinned base images make builds non-reproducible: the same Dockerfile produces different images on different days, and rollbacks rebuild on a base the original was never tested with.

- Pin to at least minor version plus variant: `FROM node:20.12-bookworm-slim`, `FROM python:3.12.3-slim`, not `node:latest` or `python:3`.
- For production images, prefer pinning by digest for full immutability: `FROM node:20.12-bookworm-slim@sha256:...` (get the digest with `docker buildx imagetools inspect <image:tag>`).
- Pin every stage of a multi-stage build, including the throwaway builder stage and any `COPY --from=<image>` references.
- The same applies to images referenced outside Dockerfiles that you're asked to write: compose files, CI service containers, base images in build scripts.
- When updating a pinned base, change the pin explicitly in its own commit so the upgrade is visible, testable, and revertible, instead of arriving as a silent side effect of the next build.
- If the project has no convention yet, choose the current stable version and pin it; do not leave the choice to the registry.

**Red flags that you're about to violate this:**

- "latest keeps them automatically up to date with security patches..."
- "Every tutorial Dockerfile uses node:latest..."
- "Pinning means someone has to maintain version bumps..."
- "It's just the builder stage, the final image is what matters..."
- "python:3 is pinned enough, the major version won't change behavior..."
