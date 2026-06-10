### Run Containers as a Non-Root User

ALWAYS end a production Dockerfile with a non-root `USER`. A container with no `USER` instruction runs the application as root, and root in the container is the difference between a contained bug and a foothold.

- Use the image's built-in unprivileged user when one exists (`USER node` on Node images) or create one: `RUN addgroup --system app && adduser --system --ingroup app app` then `USER app`.
- Place `USER` after build steps that need root (package installs) and before the `CMD`/`ENTRYPOINT`. Build as root if needed; never run as root.
- `chown` the specific directories the app writes (`COPY --chown=app:app`, or `chown app:app /app/data`) instead of `chmod -R 777`, which is root-by-other-means.
- Need a port below 1024? Listen on 8080 and map it, rather than keeping root for the bind.
- When a container hits a permission error, fix it by granting the unprivileged user access to the specific path — never by adding `USER root`, deleting the `USER` line, or running the container `--privileged`.
- In Kubernetes manifests you write, set `runAsNonRoot: true` and `allowPrivilegeEscalation: false` in the securityContext so the image-level decision is enforced at admission.

**Red flags that you're about to violate this:**

- "The base image examples don't set USER either..."
- "Permission denied, switching to root is the quickest unblock..."
- "It's containerized anyway, root inside the box is harmless..."
- "chmod 777 on the data dir and everyone's problem is solved..."
- "I'll sort out the user stuff after the container actually runs..."
