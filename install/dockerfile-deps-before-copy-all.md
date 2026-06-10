### Install Dependencies Before COPY Dot in Dockerfiles

ALWAYS order Dockerfile layers from least-frequently-changed to most-frequently-changed. Copy dependency manifests alone, install dependencies, and only then `COPY . .` — never the reverse. A `COPY . .` above the install step means every source edit re-runs the full dependency install.

- Node: `COPY package.json package-lock.json ./` then `RUN npm ci` then `COPY . .`
- Python: `COPY requirements.txt ./` (or `pyproject.toml` + lockfile) then `RUN pip install -r requirements.txt` then `COPY . .`
- Go/Rust: copy `go.mod`/`go.sum` or `Cargo.toml`/`Cargo.lock`, fetch/build deps, then copy source.
- System packages (`apt-get install`, `apk add`) change least often of all; they go above the dependency install, never below the source copy.
- Add a `.dockerignore` excluding `.git`, `node_modules`, build output, and local env files — a bloated COPY context both slows the build and invalidates cache with files that don't affect the image.
- When editing an existing Dockerfile, preserve its cache ordering; do not collapse separated COPY steps into one `COPY . .` for tidiness.
- Use the lockfile-honoring install command (`npm ci`, not `npm install`) so the cached layer is also reproducible.

**Red flags that you're about to violate this:**

- "COPY . . first is simpler and the build still passes..."
- "Build speed isn't part of what they asked for..."
- "Merging these COPY lines makes the Dockerfile cleaner..."
- "The deps layer rebuilds either way the first time, so ordering doesn't matter..."
- "It's a small project, the install only takes a minute..."
