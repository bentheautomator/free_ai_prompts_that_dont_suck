---
title: Build Once, Promote the Same Artifact
slug: build-once-promote-the-same-artifact
category: ci-cd
tags: [universal, ci, deploy]
works_with: all
severity: high
one_liner: "Stops the AI from rebuilding at deploy time and shipping an artifact CI never tested"
---

# Build Once, Promote the Same Artifact

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from writing pipelines that build a fresh artifact for each stage, so the thing tested and the thing deployed are merely similar.

**[Copy-paste ready version](../../install/build-once-promote-the-same-artifact.md)** — just the instruction block, no explanation.

## The Problem

A common AI-generated pipeline shape: the test job checks out the code and runs `docker build` + tests; the staging job checks out the code and runs `docker build` + deploy; the production job checks out the code and runs `docker build` + deploy. Three builds, from the same commit, that everyone treats as the same artifact. They aren't. Between builds, base images move, unpinned transitive dependencies resolve differently, build args differ, timestamps change. The binary that passed the test suite was never deployed; the binary that was deployed was never tested. Most days the difference is zero. The day a base image updates between your staging build and your production build, the difference is your incident.

This also quietly destroys two things teams assume they have. Rollbacks: "redeploy the previous version" rebuilds the previous commit *today*, producing an artifact that never existed before, in the middle of an incident — the worst possible moment to run an unrepeatable build. And provenance: when production misbehaves, nobody can fetch the exact artifact that's running and test it, because it was built ephemerally in a deploy job and exists nowhere else.

Assistants produce per-stage rebuilds because each job is generated as a self-contained unit — checkout, build, act — and that template is correct for any one job in isolation. Plumbing one artifact through registry pushes and digest references across jobs is more wiring, so unless the rule demands it, three independent builds is the natural output.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

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

---

## Why It Works

1. **It makes "tested" a property of bytes, not of commits.** The test suite verified an artifact; only by deploying that artifact does the green result transfer to production. Rebuilding launders an untested binary under a tested commit hash.
2. **Content addressing turns sameness from an assumption into a check** — a digest match is proof; "built from the same SHA" is a hope about every unpinned input in the build.
3. **It moves the unrepeatable operation out of the incident path.** Builds are the least deterministic step in the pipeline; doing them once, in advance, means rollback is a fetch instead of a gamble.
4. **The config-at-deploy-time rule protects the invariant from the most common exception request**, because the moment environments get different builds, the promotion model — and the meaning of staging — is gone.

## Origin

A team's staging and production deploys each rebuilt the application image from the release commit. A base image's weekly update landed in the four-hour window between the staging build (which soak-tested clean) and the production build, bringing a new OpenSSL with stricter defaults that broke connections to an older internal service. Production failed with an error staging had never produced from "the same release." The incident review's diagram had two boxes labeled with one version number and two different image digests underneath — which became the slide that justified rebuilding the pipeline around promotion.
