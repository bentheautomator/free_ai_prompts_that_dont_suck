### Deploy by Immutable Image Tag, Never Latest

NEVER reference `:latest`, an untagged image, or any mutable tag (`stable`, `prod`, `main`) in a deployment manifest, task definition, compose file, or Helm values. A deploy must name an immutable artifact; otherwise rollback, audit, and "what is running right now" are all undefined.

- Tag images per build with something unique and traceable: the git SHA (`myapp:3f2a91c`), or version plus SHA (`myapp:1.4.2-3f2a91c`). For the strongest guarantee, deploy by digest: `myapp@sha256:...`.
- A release is a manifest change: bump the tag in the Deployment/values file, apply, done. Rollback is re-applying the previous tag — which only works if the previous tag still points at the previous build, i.e., never if the tag is `latest`.
- Never "deploy" by re-pushing an existing tag and restarting pods. Mutable-tag re-push means two replicas can run different code under the same name and the registry has silently lost the old build's address.
- Do not set `imagePullPolicy: Always` to make mutable tags behave; that's a workaround that adds a registry dependency to every pod start and still can't tell you what's running.
- If the project currently deploys `latest`, flag it before making changes that assume version identity (rollbacks, canaries, incident timelines) — those features don't actually exist yet.

**Red flags that you're about to violate this:**

- "latest is what the existing manifests use, I'll stay consistent..."
- "Re-pushing the tag and restarting the pods is the fastest way to ship this fix..."
- "imagePullPolicy: Always means the pods will always get the newest build, problem solved..."
- "Tagging every build clutters the registry..."
- "We can always tell what's running from the deploy timestamps..."
