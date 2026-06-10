---
title: Pin Actions and Images to Immutable Refs
slug: pin-actions-and-images-to-immutable-refs
category: ci-cd
tags: [universal, ci, security]
works_with: all
severity: high
one_liner: "Stops the AI from pinning CI actions and images to tags that can move"
---

# Pin Actions and Images to Immutable Refs

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from referencing third-party actions and container images by mutable tags like `@v4` or `:latest` that can change underneath the pipeline.

**[Copy-paste ready version](../../install/pin-actions-and-images-to-immutable-refs.md)** — just the instruction block, no explanation.

## The Problem

`uses: some-org/setup-tool@v2` looks pinned. It isn't. `v2` is a git tag, and git tags move — sometimes because the maintainer force-pushed a fix, sometimes because the maintainer's account was compromised and the tag now points at a credential stealer running with access to your repo's secrets. The same goes for `image: node:latest` and even `node:20`, which is a different image this month than last month. Your pipeline's behavior is now a function of what strangers did to the internet since the last run.

The practical failures come in two flavors. The boring one: a tag moves, the build breaks or subtly changes, and you burn a day bisecting a "regression" that isn't in your repo at all. The catastrophic one: a popular action's tags get repointed at malicious code, and every workflow consuming it by tag executes the payload with secrets in the environment — an attack that has happened in the wild and works precisely because mutable tags are the ecosystem default.

Assistants write mutable references because that's what the README of every action shows, what most example code uses, and what's shortest. Left to defaults, they'll also "fix" a broken pinned workflow by upgrading the pin to a floating tag, trading one visible failure for a permanent invisible one.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Pin Actions and Images to Immutable Refs

ALWAYS pin third-party CI actions to a full commit SHA and container images to a digest. NEVER reference them by mutable tags — `@v4`, `@main`, `:latest`, or bare version tags like `node:20`.

A mutable tag means the code your pipeline executes can change without any commit to your repo. That is both a reproducibility bug and a supply-chain hole.

- GitHub Actions: write `uses: org/action@<40-char-sha> # v4.1.2`, with the human-readable version in a trailing comment. The SHA is the pin; the comment is documentation.
- Container images: write `image: node:20.11.1-bookworm@sha256:<digest>`. The tag tells humans what it is; the digest is what actually gets pulled.
- Never resolve a pin by guessing or from memory. Look up the SHA for the release tag from the action's repository, or the digest from the registry, and record where it came from in the PR.
- If an existing workflow uses floating tags, don't silently churn it in an unrelated PR — flag it to the user as a supply-chain risk and offer to pin everything in a dedicated change.
- When a pinned action needs updating, update the SHA and the version comment together so they never drift apart.
- First-party actions referenced from within the same trusted org may follow that org's existing convention; everything third-party gets a SHA.

**Red flags that you're about to violate this:**

- "The action's README says to use @v4, so that's the supported way."
- "Tags basically never move; SHAs are paranoid."
- ":latest means we always get the bug fixes for free."
- "The SHA makes the YAML ugly and hard to review."
- "I'll use the tag for now and pin it properly later."

---

## Why It Works

1. **It removes a hidden input from the build function.** Pipelines pinned by SHA/digest behave the same on every run; mutable tags make build behavior depend on third-party state your repo never sees.
2. **It converts a trust assumption into a verification.** A tag trusts the maintainer's account security forever; a SHA trusts the specific code you reviewed once.
3. **The comment convention keeps pins maintainable**, which kills the strongest real argument against SHAs — that nobody can tell what version they're on.
4. **It blocks the failure-mode swap** where the assistant "fixes" a stale pin by floating it, exchanging a loud, debuggable break for a quiet, permanent exposure.

## Origin

A team's deploy workflow consumed a popular tag-pinned third-party action. The action's repo was compromised and its version tags repointed at code that dumped the runner's environment to an external host. The team's workflow ran twice before the ecosystem-wide alarm went out, and they spent a week rotating every secret that workflow could see, none of which their own commits had touched.
