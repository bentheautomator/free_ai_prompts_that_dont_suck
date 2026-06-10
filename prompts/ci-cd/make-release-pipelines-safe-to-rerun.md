---
title: Make Release Pipelines Safe to Rerun
slug: make-release-pipelines-safe-to-rerun
category: ci-cd
tags: [universal, ci, release]
works_with: all
severity: high
one_liner: "Stops the AI from writing release automation that breaks if it runs twice"
---

# Make Release Pipelines Safe to Rerun

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from writing release jobs whose second execution corrupts state, double-publishes, or fails in a way the first execution made unrecoverable.

**[Copy-paste ready version](../../install/make-release-pipelines-safe-to-rerun.md)** — just the instruction block, no explanation.

## The Problem

Release pipelines fail in the middle. Not sometimes — routinely. The registry times out after the tag is pushed; the changelog commit lands but the artifact upload dies; the runner gets recycled between "publish package" and "create GitHub release." The first question after any of these is "can I just rerun it?" and for most AI-written release automation the answer is no: the rerun fails on "tag already exists," or publishes a second artifact under a bumped version nobody asked for, or appends the changelog entry twice.

A release job that can't be rerun converts every transient failure into a manual surgery session. Someone has to reconstruct which of the seven steps completed, delete a tag, yank a half-published package, and hand-run the remainder in the right order — under time pressure, because releases happen when people are waiting for them. The pipeline that was supposed to remove human error from releases now manufactures the most error-prone human task in the company.

Assistants write non-idempotent release steps because the happy path is the only path the task description mentions. `git tag v$VERSION && git push --tags && npm publish` is correct exactly once. Nothing in "automate the release" says "and assume this will be executed 1.5 times on average," so nothing in the generated YAML does either.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Make Release Pipelines Safe to Rerun

ALWAYS write release automation so that running it a second time — after a partial failure, or by accident — either completes the release correctly or exits cleanly as a no-op. NEVER write a release step whose second execution errors on the first execution's side effects or publishes duplicates.

Release pipelines fail mid-run as a matter of course. Rerunnability is not a nice-to-have; it is the recovery mechanism.

- Make each side-effecting step check-then-act: skip tagging if the tag already exists *and points at the right commit*; skip publishing if this exact version is already in the registry; skip release creation if the release exists. "Already done" is success, not an error.
- Fail loudly on conflicts: if the tag exists but points at a *different* commit, that's not a skip, that's a stop-everything error. Idempotent does not mean conflict-blind.
- Order steps so the points of no return come last: validate, build, and test everything before the first publish; push the tag and announce only after artifacts are durably uploaded.
- Never auto-increment the version to dodge an "already exists" error. Same release, same version — a rerun that mints v1.4.3 because v1.4.2 half-exists has created a second problem.
- Derive the version from a single source (the tag, or one version file) rather than computing it independently in multiple steps, so a rerun can't disagree with itself.
- State in the PR how the pipeline behaves when rerun after each side-effecting step. If you can't answer that for a step, the step isn't done.

**Red flags that you're about to violate this:**

- "The release job only runs once per version, so reruns don't matter."
- "If it fails, someone can clean up by hand."
- "I'll bump the patch version on retry so the publish doesn't collide."
- "Checking whether the tag exists is extra complexity for an edge case."
- "The happy path works; failure handling can come later."

---

## Why It Works

1. **It builds for the actual execution count.** Release jobs run "once, plus reruns"; designing for exactly-once is designing for a frequency that doesn't occur in practice.
2. **Check-then-act plus loud conflicts splits idempotency correctly** — reruns of the same intent are no-ops, while genuine state divergence still halts the line, so safety doesn't become blindness.
3. **Ordering by reversibility shrinks the disaster window**: a failure before the first publish costs a rerun; the rule pushes all the irreversible steps past everything that can be validated.
4. **The per-step rerun question in the PR is a falsifiable spec.** "What happens if this runs again after step 4?" has a checkable answer, unlike "the release automation is robust."

## Origin

A release workflow pushed the version tag, published to the package registry, then failed creating the platform release page due to an API blip. The on-call engineer clicked rerun; the job died at `git tag` on "already exists," so they deleted the tag and reran again — and the publish step, finding the version live in the registry, errored too, leaving the team to finish the release by hand from three different laptops. Total automation time saved that quarter: negative four hours, all of them between midnight and two.
