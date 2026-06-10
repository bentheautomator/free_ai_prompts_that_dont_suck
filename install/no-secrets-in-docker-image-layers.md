### Keep Secrets Out of Docker Image Layers

NEVER put credentials into a Docker image by any route: no `ENV SECRET=...`, no `ARG TOKEN` used in a RUN, no `COPY` of keyfiles, no echoing creds into config files mid-build. Layers are immutable and inspectable; `docker history` and `docker save` recover everything, and a later `rm` removes nothing from earlier layers.

- For build-time secrets, use BuildKit secret mounts: `RUN --mount=type=secret,id=npmrc,target=/root/.npmrc npm ci`, passed with `docker build --secret id=npmrc,src=$HOME/.npmrc`. The secret exists only for that command, in no layer.
- For git-over-SSH dependencies, use `RUN --mount=type=ssh git clone ...` with `docker build --ssh default` — never COPY a private key into the image.
- Runtime secrets enter at runtime: injected env vars, mounted files, or the platform's secret store — never written into the image so the container "works out of the box."
- The COPY-use-delete pattern is a leak, not a mitigation. So is a multi-stage build that copies the secret into the builder stage and then copies an artifact forward while the builder layers go to cache — build caches are pullable too.
- Add `.dockerignore` entries for `.env`, `.npmrc`, `*.pem`, and `.ssh/` so a broad `COPY . .` can't sweep credentials in silently.
- If you find a secret already baked into an image, say so: it needs rotation, not just a fixed Dockerfile, because every pushed copy still contains it.

**Red flags that you're about to violate this:**

- "I'll pass the token as a build ARG, that's not the same as hardcoding it..."
- "The RUN step deletes the key right after using it..."
- "Only the builder stage sees the secret, the final image is clean..."
- "This registry is private, who's going to inspect the layers..."
- "ENV is how all the docker-compose tutorials inject credentials..."
