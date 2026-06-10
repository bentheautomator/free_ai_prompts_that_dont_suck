### Ship Runtime Images, Not Build Environments

ALWAYS use a multi-stage build for compiled or bundled applications. The production image contains the runtime and the built artifact — not compilers, dev dependencies, source files, test suites, or package manager caches.

- Pattern: a `build` stage (`FROM node:20.12-slim AS build`) that installs everything and compiles, then a runtime stage (`FROM node:20.12-slim`) that does `COPY --from=build /app/dist ./dist` plus a production-only dependency install (`npm ci --omit=dev`).
- Compiled languages go further: build in the full toolchain image, run from `debian:slim`, `distroless`, or `alpine` with just the binary. A Go or Rust service has no business shipping its compiler.
- Do not ship: `devDependencies`, `.git`, test directories, build caches, docs, or source files the runtime doesn't read. If the entrypoint doesn't execute it, it doesn't belong in the final stage.
- Keep `apt-get install` in the build stage unless the runtime genuinely needs the library; when it does, install the runtime lib (`libpq5`), not the dev package (`libpq-dev`).
- Maintain a `.dockerignore` so the build context itself stays lean.
- When you finish a Dockerfile, report the final image size (`docker images <name>`). If a Node service image is over ~400 MB or a Go service over ~50 MB, something that doesn't belong is in there.

**Red flags that you're about to violate this:**

- "Single-stage is simpler and image size wasn't in the requirements..."
- "Disk is cheap, a fat image hurts nobody..."
- "Keeping devDependencies in the image makes debugging in prod easier..."
- "I'll copy the whole /app directory forward, sorting out what's needed is fiddly..."
- "The scanner findings are all in build tools, so they're not real vulnerabilities..."
