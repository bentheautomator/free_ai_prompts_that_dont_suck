### Build Once, Promote the Same Artifact

Build each release artifact exactly once, then promote that identical artifact — by digest or checksum — through test, staging, and production. NEVER write a pipeline where a deploy stage rebuilds from source, because a rebuild is a different artifact, and a different artifact is untested by definition.

- Structure the pipeline as build → test → promote: one build job produces the image/package, pushes it to a registry or artifact store, and outputs its immutable identifier; every later stage consumes that identifier. Deploy jobs contain no compile, bundle, or `docker build` steps.
- Pass the artifact by content address, not by name: an image *digest* (`@sha256:...`) or a checksummed file — not a `:latest` tag, not even a version tag, which can be repushed. The digest is the proof that staging and production ran the same bytes.
- Use the platform's artifact mechanism (or a registry) to carry outputs between jobs; never have a downstream job re-derive what an upstream job already built and tested.
- Rollback must mean redeploying a previously built, previously verified artifact fetched from the store — never rebuilding an old commit during an incident.
- Stage-specific configuration goes in at deploy time (env vars, config layers, mounted files), not bake time. If staging and production need different *builds*, that's a design problem to raise, because it makes "tested in staging" unverifiable for production.
- If the existing pipeline rebuilds per stage, don't extend the pattern when adding stages — flag it and propose consolidating to a single build with promotion.

**Red flags that you're about to violate this:**

- "Each job checks out and builds; that's the standard self-contained job pattern."
- "Rebuilding from the same commit produces the same artifact anyway."
- "Wiring the registry push and digest output is overkill for this pipeline."
- "Production needs a different build flag, so it gets its own build."
- "We can always rebuild any old version if we need to roll back."
